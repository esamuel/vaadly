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
Object.defineProperty(exports, "__esModule", { value: true });
exports.health = exports.ai_intake = exports.sendNotifyEnhanced = exports.sendNotify = exports.payments = exports.dispatchCron = exports.onWorkOrderCreate = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v2"));
const classify_1 = require("./classify");
const dispatch_1 = require("./dispatch");
const webhooks_1 = require("./webhooks");
const notify_1 = require("./notify");
const notify_enhanced_1 = require("./notify_enhanced");
const ai_intake_1 = require("./ai_intake");
// Initialize Firebase Admin
admin.initializeApp();
// Trigger: classify on new work order
exports.onWorkOrderCreate = functions.firestore
    .onDocumentCreated('buildings/{buildingId}/work_orders/{workOrderId}', async (event) => {
    const { buildingId, workOrderId } = event.params;
    await (0, classify_1.classifyWorkOrder)(buildingId, workOrderId);
});
// Scheduled: dispatch pending work orders (or chain after classify)
exports.dispatchCron = functions.scheduler
    .onSchedule('every 1 minutes', async () => {
    await (0, dispatch_1.dispatchWorkOrder)();
});
// HTTPS: payment provider webhook
exports.payments = functions.https.onRequest(webhooks_1.paymentWebhook);
// HTTPS: send email/push notifications
exports.sendNotify = functions.https.onRequest(notify_1.notify);
// HTTPS: enhanced notifications with targeting and analytics
exports.sendNotifyEnhanced = functions.https.onRequest(notify_enhanced_1.notifyEnhanced);
// HTTPS: AI resident intake (Hebrew NL -> structured work order)
exports.ai_intake = ai_intake_1.aiIntake;
// Health check endpoint
exports.health = functions.https.onRequest((req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'vaadly-functions'
    });
});
//# sourceMappingURL=index.js.map