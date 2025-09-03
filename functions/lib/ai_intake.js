"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.aiIntake = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const openai_1 = __importDefault(require("openai"));
// HTTPS endpoint: convert NL (Hebrew-friendly) into a structured work order
// Expected JSON body: { buildingId: string, residentId?: string, text: string }
exports.aiIntake = (0, https_1.onRequest)(async (req, res) => {
    try {
        const db = admin.firestore();
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed' });
            return;
        }
        const { buildingId, residentId, text, imageBase64, imageMime } = req.body || {};
        if (!buildingId || !text || typeof text !== 'string') {
            res.status(400).json({ error: 'Missing buildingId or text' });
            return;
        }
        const prompt = `נתון טקסט חופשי מדייר/נציג ועד בעברית המתאר תקלה/בקשה תחזוקתית בבניין.
הפק תיאור מובנה להזמנה (work order) בפורמט JSON בלבד:
{
  "title": string,                // כותרת קצרה בעברית
  "description": string,          // תיאור מפורט בעברית
  "category": "plumbing|electrical|cleaning|gardening|hvac|elevator|general",
  "priority": "urgent|high|normal|low",
  "unit": string | null,          // דירה/יחידה אם מופיע בטקסט
  "attachments": string[]         // רשימת קישורים אם ידוע, אחרת ריק
}
טקסט קלט:
${text}`;
        // Prepare parsed structure, optionally using OpenAI if key is provided
        let parsed;
        const apiKey = process.env.OPENAI_API_KEY;
        if (apiKey && apiKey.trim()) {
            const openai = new openai_1.default({ apiKey });
            const completion = await openai.chat.completions.create({
                model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
                response_format: { type: 'json_object' },
                messages: [
                    { role: 'system', content: 'אתה מסייע תחזוקה לבנייני מגורים. הפלט חייב להיות JSON תקין בלבד.' },
                    { role: 'user', content: prompt },
                ],
                temperature: 0.2,
                max_tokens: 300,
            });
            const content = completion.choices[0]?.message?.content;
            if (!content) {
                res.status(502).json({ error: 'No response from AI' });
                return;
            }
            try {
                parsed = JSON.parse(content);
            }
            catch (e) {
                res.status(502).json({ error: 'Invalid AI JSON' });
                return;
            }
        }
        else {
            // Fallback parsing when no OpenAI key is present (emulator/dev mode)
            parsed = {
                title: (text || '').toString().slice(0, 120) || 'תקלה חדשה',
                description: (text || '').toString().slice(0, 5000),
                category: 'general',
                priority: 'normal',
                unit: null,
                attachments: [],
                confidence: null,
            };
        }
        const validCategories = ['plumbing', 'electrical', 'cleaning', 'gardening', 'hvac', 'elevator', 'general'];
        const validPriorities = ['urgent', 'high', 'normal', 'low'];
        const title = (parsed.title || '').toString().trim().slice(0, 120) || 'תקלה חדשה';
        const description = (parsed.description || '').toString().trim().slice(0, 5000);
        const category = validCategories.includes(parsed.category) ? parsed.category : 'general';
        const priority = validPriorities.includes(parsed.priority) ? parsed.priority : 'normal';
        const unit = parsed.unit ? String(parsed.unit).slice(0, 64) : null;
        const attachments = Array.isArray(parsed.attachments) ? parsed.attachments.filter((x) => typeof x === 'string') : [];
        const now = admin.firestore.FieldValue.serverTimestamp();
        const workOrder = {
            title,
            description,
            category,
            priority,
            unit,
            attachments,
            residentId: residentId || null,
            status: 'new',
            createdAt: now,
            updatedAt: now,
            aiConfidence: parsed.confidence || null,
            aiTraceId: null,
            _dispatchReady: true,
        };
        // Create an AI audit trace first
        const auditRef = await db.collection(`buildings/${buildingId}/ai_audit`).add({
            type: 'intake',
            input: { text },
            output: { title, description, category, priority, unit },
            model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
            confidence: parsed.confidence || null,
            timestamp: now,
            actor: 'ai_system',
        });
        workOrder.aiTraceId = auditRef.id;
        // Persist work order initially to get ID
        const orderRef = await db.collection(`buildings/${buildingId}/work_orders`).add(workOrder);
        // Optional image upload
        if (imageBase64 && typeof imageBase64 === 'string') {
            try {
                const mime = typeof imageMime === 'string' && imageMime.includes('/') ? imageMime : 'image/jpeg';
                const ext = mime.split('/')[1] || 'jpg';
                const buffer = Buffer.from(imageBase64.replace(/^data:[^;]+;base64,/, ''), 'base64');
                const filePath = `buildings/${buildingId}/wo/${orderRef.id}/${Date.now()}.${ext}`;
                const bucket = admin.storage().bucket();
                const file = bucket.file(filePath);
                await file.save(buffer, { contentType: mime, resumable: false, metadata: { cacheControl: 'public, max-age=31536000' } });
                // Try to generate a long-lived signed URL for convenience; fallback to storage path
                let downloadUrl = null;
                try {
                    const [url] = await file.getSignedUrl({ action: 'read', expires: '2100-01-01' });
                    downloadUrl = url;
                }
                catch (e) {
                    console.warn('Failed to generate signed URL, storing storage path instead');
                }
                const attachmentEntry = downloadUrl || `gs://${bucket.name}/${filePath}`;
                attachments.push(attachmentEntry);
                await orderRef.set({ attachments, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
                // Link the uploaded file in AI audit as well
                await auditRef.set({ output: { ...auditRef, attachments } }, { merge: true });
            }
            catch (uploadErr) {
                console.error('Image upload failed', uploadErr);
            }
        }
        res.json({ id: orderRef.id, ...workOrder });
    }
    catch (err) {
        console.error('ai_intake error', err);
        res.status(500).json({ error: 'Internal error' });
    }
});
//# sourceMappingURL=ai_intake.js.map