import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";

admin.initializeApp();

export const dailyReminder = onSchedule(
  {
    schedule: "35 10 * * *",
    timeZone: "Asia/Kathmandu",
  },
  async () => {
    await admin.messaging().send({
      topic: "all",
      notification: {
        title: "Good Morning",
        body: "Don't forget to track your expenses today!",
      },
    });

    console.log("Notification sent");
  },
);
