/**
 * Cloud Functions for maintaining destination stats counters.
 *
 * These functions automatically increment/decrement stats fields
 * on parent destination documents when reviews or locations are
 * created or deleted, eliminating the need for expensive client-side
 * aggregation queries.
 *
 * Stats maintained:
 * - postCount: number of reviews for a destination
 * - engagementCount: sum of likeCount + commentCount + saveCount
 * - locationCount: number of locations for a destination
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ── Review Triggers ──────────────────────────────────────────

/**
 * When a review is created, increment postCount and add engagement stats
 * on the parent destination document.
 */
export const onReviewCreated = functions.firestore
    .document("reviews/{reviewId}")
    .onCreate(async (snap) => {
        const review = snap.data();
        const destinationId = review.destinationId;

        if (!destinationId) {
            console.log("Review has no destinationId, skipping stats update");
            return;
        }

        const engagement =
            (review.likeCount || 0) +
            (review.commentCount || 0) +
            (review.saveCount || 0);

        try {
            await db
                .collection("destinations")
                .doc(destinationId)
                .update({
                    postCount: admin.firestore.FieldValue.increment(1),
                    engagementCount: admin.firestore.FieldValue.increment(engagement),
                });
            console.log(
                `Incremented postCount and engagementCount for ${destinationId}`
            );
        } catch (error) {
            console.error(`Failed to update stats for ${destinationId}:`, error);
        }
    });

/**
 * When a review is deleted, decrement postCount and subtract engagement stats
 * from the parent destination document.
 */
export const onReviewDeleted = functions.firestore
    .document("reviews/{reviewId}")
    .onDelete(async (snap) => {
        const review = snap.data();
        const destinationId = review.destinationId;

        if (!destinationId) {
            console.log("Review has no destinationId, skipping stats update");
            return;
        }

        const engagement =
            (review.likeCount || 0) +
            (review.commentCount || 0) +
            (review.saveCount || 0);

        try {
            await db
                .collection("destinations")
                .doc(destinationId)
                .update({
                    postCount: admin.firestore.FieldValue.increment(-1),
                    engagementCount: admin.firestore.FieldValue.increment(-engagement),
                });
            console.log(
                `Decremented postCount and engagementCount for ${destinationId}`
            );
        } catch (error) {
            console.error(`Failed to update stats for ${destinationId}:`, error);
        }
    });

// ── Location Triggers ────────────────────────────────────────

/**
 * When a location is created, increment locationCount
 * on the parent destination document.
 */
export const onLocationCreated = functions.firestore
    .document("locations/{locationId}")
    .onCreate(async (snap) => {
        const location = snap.data();
        const destinationId = location.destinationId;

        if (!destinationId) {
            console.log("Location has no destinationId, skipping stats update");
            return;
        }

        try {
            await db
                .collection("destinations")
                .doc(destinationId)
                .update({
                    locationCount: admin.firestore.FieldValue.increment(1),
                });
            console.log(`Incremented locationCount for ${destinationId}`);
        } catch (error) {
            console.error(`Failed to update stats for ${destinationId}:`, error);
        }
    });

/**
 * When a location is deleted, decrement locationCount
 * on the parent destination document.
 */
export const onLocationDeleted = functions.firestore
    .document("locations/{locationId}")
    .onDelete(async (snap) => {
        const location = snap.data();
        const destinationId = location.destinationId;

        if (!destinationId) {
            console.log("Location has no destinationId, skipping stats update");
            return;
        }

        try {
            await db
                .collection("destinations")
                .doc(destinationId)
                .update({
                    locationCount: admin.firestore.FieldValue.increment(-1),
                });
            console.log(`Decremented locationCount for ${destinationId}`);
        } catch (error) {
            console.error(`Failed to update stats for ${destinationId}:`, error);
        }
    });
