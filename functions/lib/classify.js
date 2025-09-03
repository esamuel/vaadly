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
exports.classifyWorkOrder = classifyWorkOrder;
const admin = __importStar(require("firebase-admin"));
const openai_1 = __importDefault(require("openai"));
async function classifyWorkOrder(buildingId, workOrderId) {
    const db = admin.firestore();
    try {
        const docRef = db.doc(`buildings/${buildingId}/work_orders/${workOrderId}`);
        const snap = await docRef.get();
        if (!snap.exists) {
            console.log(`Work order ${workOrderId} not found`);
            return;
        }
        const data = snap.data();
        const { title = '', description = '' } = data;
        if (!title && !description) {
            console.log(`Work order ${workOrderId} has no content to classify`);
            return;
        }
        // Prepare prompt for AI classification
        const prompt = `Classify this building maintenance issue into the following categories and priority levels:

Categories: plumbing, electrical, cleaning, gardening, hvac, elevator, general
Priority: urgent, high, normal, low

Please respond with JSON only in this format:
{
  "category": "category_name",
  "priority": "priority_level",
  "confidence": 0.95
}

Issue Title: ${title}
Issue Description: ${description}`;
        // Optionally call OpenAI if key exists; otherwise use heuristic fallback
        let classification;
        const apiKey = process.env.OPENAI_API_KEY;
        if (apiKey && apiKey.trim()) {
            const openai = new openai_1.default({ apiKey });
            const response = await openai.chat.completions.create({
                model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
                response_format: { type: 'json_object' },
                messages: [
                    {
                        role: 'system',
                        content: 'You are a building maintenance expert. Classify issues accurately and assign appropriate priority levels.'
                    },
                    {
                        role: 'user',
                        content: prompt
                    }
                ],
                temperature: 0.1, // Low temperature for consistent classification
                max_tokens: 150
            });
            const content = response.choices[0]?.message?.content;
            if (!content) {
                throw new Error('No response from OpenAI');
            }
            classification = JSON.parse(content);
        }
        else {
            // Simple heuristics for local dev without OpenAI
            const t = `${title} ${description}`.toLowerCase();
            const guessCategory = t.includes('מים') || t.includes('צנרת') ? 'plumbing'
                : t.includes('חשמל') ? 'electrical'
                    : t.includes('מעלית') ? 'elevator'
                        : 'general';
            classification = {
                category: guessCategory,
                priority: 'normal',
                confidence: 0.0
            };
        }
        const { category, priority, confidence } = classification;
        // Validate classification
        const validCategories = ['plumbing', 'electrical', 'cleaning', 'gardening', 'hvac', 'elevator', 'general'];
        const validPriorities = ['urgent', 'high', 'normal', 'low'];
        if (!validCategories.includes(category)) {
            console.warn(`Invalid category from AI: ${category}, defaulting to 'general'`);
            classification.category = 'general';
        }
        if (!validPriorities.includes(priority)) {
            console.warn(`Invalid priority from AI: ${priority}, defaulting to 'normal'`);
            classification.priority = 'normal';
        }
        // Update work order with classification
        await docRef.set({
            category: classification.category,
            priority: classification.priority,
            aiConfidence: confidence || 0.0,
            classifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            _dispatchReady: true // Mark for dispatch
        }, { merge: true });
        // Log classification
        console.log(`Work order ${workOrderId} classified as ${classification.category} with ${classification.priority} priority`);
        // Create audit log
        await db.collection(`buildings/${buildingId}/audit`).add({
            event: 'work_order_classified',
            workOrderId: workOrderId,
            category: classification.category,
            priority: classification.priority,
            aiConfidence: confidence || 0.0,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            userId: 'ai_system'
        });
    }
    catch (error) {
        console.error(`Error classifying work order ${workOrderId}:`, error);
        // Fallback: set default values and mark for dispatch
        try {
            await db.doc(`buildings/${buildingId}/work_orders/${workOrderId}`).set({
                category: 'general',
                priority: 'normal',
                aiConfidence: 0.0,
                classifiedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                _dispatchReady: true
            }, { merge: true });
            console.log(`Set fallback classification for work order ${workOrderId}`);
        }
        catch (fallbackError) {
            console.error(`Failed to set fallback classification:`, fallbackError);
        }
    }
}
//# sourceMappingURL=classify.js.map