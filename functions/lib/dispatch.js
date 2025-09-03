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
exports.dispatchWorkOrder = dispatchWorkOrder;
exports.dispatchSpecificWorkOrder = dispatchSpecificWorkOrder;
const admin = __importStar(require("firebase-admin"));
async function dispatchWorkOrder() {
    try {
        const db = admin.firestore();
        console.log('Starting work order dispatch...');
        // Get all work orders ready for dispatch
        const query = await db.collectionGroup('work_orders')
            .where('_dispatchReady', '==', true)
            .limit(10) // Process in batches
            .get();
        if (query.empty) {
            console.log('No work orders ready for dispatch');
            return;
        }
        console.log(`Found ${query.docs.length} work orders ready for dispatch`);
        for (const doc of query.docs) {
            try {
                await dispatchSingleWorkOrder(db, doc);
            }
            catch (error) {
                console.error(`Error dispatching work order ${doc.id}:`, error);
                // Mark as failed to prevent infinite retries
                await doc.ref.set({
                    _dispatchReady: false,
                    _dispatchFailed: true,
                    _dispatchError: error instanceof Error ? error.message : 'Unknown error',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });
            }
        }
        console.log('Work order dispatch completed');
    }
    catch (error) {
        console.error('Error in work order dispatch:', error);
    }
}
async function dispatchSingleWorkOrder(db, doc) {
    const data = doc.data();
    const buildingId = doc.ref.path.split('/')[1]; // Extract building ID from path
    const workOrderId = doc.id;
    console.log(`Dispatching work order ${workOrderId} in building ${buildingId}`);
    // Get work order details
    const { category = 'general', priority = 'normal', title = '' } = data || {};
    // Find suitable vendors for this category
    const vendorsQuery = await db.collection(`buildings/${buildingId}/vendors`)
        .where('category', '==', category)
        .where('status', '==', 'active')
        .orderBy('isDefault', 'desc')
        .orderBy('rating', 'desc')
        .limit(3) // Get top 3 vendors
        .get();
    if (vendorsQuery.empty) {
        console.log(`No active vendors found for category ${category} in building ${buildingId}`);
        // Mark as dispatched but no vendor available
        await doc.ref.set({
            _dispatchReady: false,
            _dispatched: true,
            _noVendorAvailable: true,
            status: 'pending_vendor',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        // Create announcement about vendor needed
        await db.collection(`buildings/${buildingId}/announcements`).add({
            title: 'Vendor Needed',
            body: `No vendor available for ${category} work order: ${title}`,
            type: 'vendor_needed',
            category: category,
            priority: priority,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return;
    }
    // Select the best vendor (default first, then highest rated)
    const selectedVendor = vendorsQuery.docs[0];
    const vendorId = selectedVendor.id;
    const vendorData = selectedVendor.data();
    console.log(`Selected vendor ${vendorId} (${vendorData.name}) for work order ${workOrderId}`);
    // Update work order with vendor assignment
    await doc.ref.set({
        _dispatchReady: false,
        _dispatched: true,
        assignedVendor: vendorId,
        vendorName: vendorData.name,
        status: 'assigned',
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    // Create vendor notification
    await db.collection(`buildings/${buildingId}/announcements`).add({
        title: 'New Work Order Assigned',
        body: `Work order "${title}" has been assigned to ${vendorData.name}`,
        type: 'work_order_assigned',
        workOrderId: workOrderId,
        vendorId: vendorId,
        category: category,
        priority: priority,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // Update vendor stats
    await selectedVendor.ref.set({
        lastAssigned: admin.firestore.FieldValue.serverTimestamp(),
        totalAssigned: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    // Create audit log
    await db.collection(`buildings/${buildingId}/audit`).add({
        event: 'work_order_dispatched',
        workOrderId: workOrderId,
        vendorId: vendorId,
        vendorName: vendorData.name,
        category: category,
        priority: priority,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        userId: 'dispatch_system'
    });
    console.log(`Successfully dispatched work order ${workOrderId} to vendor ${vendorId}`);
}
// Function to manually dispatch a specific work order
async function dispatchSpecificWorkOrder(buildingId, workOrderId) {
    try {
        const db = admin.firestore();
        const docRef = db.doc(`buildings/${buildingId}/work_orders/${workOrderId}`);
        const doc = await docRef.get();
        if (!doc.exists) {
            throw new Error(`Work order ${workOrderId} not found`);
        }
        await dispatchSingleWorkOrder(db, doc);
        return { success: true, message: 'Work order dispatched successfully' };
    }
    catch (error) {
        console.error(`Error dispatching specific work order:`, error);
        return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
}
//# sourceMappingURL=dispatch.js.map