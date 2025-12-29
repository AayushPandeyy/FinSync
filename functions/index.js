const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.processSubscriptionsDaily = functions.pubsub
    .schedule("every 5 minutes")
    .timeZone("Asia/Kathmandu")
    .onRun(async () => {
      const today = new Date().toISOString().split("T")[0];
      console.log("Running subscription processor for", today);

      const usersSnapshot = await db.collection("Subscriptions").get();

      for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;

        const subsSnapshot = await db
            .collection("Subscriptions")
            .doc(uid)
            .collection("subscription")
            .where("isActive", "==", true)
            .get();

        for (const subDoc of subsSnapshot.docs) {
          const sub = subDoc.data();

          if (!sub.nextBillingDate) continue;

          const dueDate =
          sub.nextBillingDate.toDate().toISOString().split("T")[0];

          // ❌ Not due today
          if (dueDate !== today) continue;

          // ❌ Already processed today (duplicate protection)
          if (sub.lastProcessedDate === today) continue;

          console.log(`Processing subscription ${subDoc.id} for user ${uid}`);

          // 1️⃣ Create expense transaction
          await db
              .collection("Transactions")
              .doc(uid)
              .collection("transaction")
              .add({
                title: sub.name,
                amount: sub.amount,
                category: sub.category,
                date: admin.firestore.Timestamp.now(),
                description: "Auto subscription payment",
                type: "expense",
                source: "subscription",
                subscriptionId: subDoc.id,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });

          // 2️⃣ Calculate next billing date
          const nextDate = sub.nextBillingDate.toDate();

          switch (sub.billingCycle) {
            case "Weekly":
              nextDate.setDate(nextDate.getDate() + 7);
              break;
            case "Monthly":
              nextDate.setMonth(nextDate.getMonth() + 1);
              break;
            case "Yearly":
              nextDate.setFullYear(nextDate.getFullYear() + 1);
              break;
          }

          // 3️⃣ Update subscription safely
          await subDoc.ref.update({
            nextBillingDate: admin.firestore.Timestamp.fromDate(nextDate),
            lastProcessedDate: today,
          });
        }
      }

      console.log("Subscription processing completed");
      return null;
    });
