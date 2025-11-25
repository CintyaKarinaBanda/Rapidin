const functions = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyOrderStatusUpdate = functions.onDocumentUpdated(
    "orders/{orderId}",
    async (event) => {
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();

      // Only trigger when STATUS changes
      if (beforeData.status === afterData.status) {
        return null;
      }

      const clientID = afterData.clientID;

      // Get the user's FCM token
      const userDoc = await admin.firestore()
      .collection("users")
      .doc(clientID)
      .get();

      if (!userDoc.exists) {
          console.log("User doc does not exist.");
          return null;
      }

      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) {
          console.log("User has no FCM token.");
          return null;
      }

      console.log("Sending push to:", fcmToken);

      const payload = {
          notification: {
              title: "Actualización de tu pedido",
              body: `El estado cambió a: ${afterData.status}`,
          },
          data: {
              type: "order_update",
              orderId: event.params.orderId,
          },
      };

        // Send the push notification
        await admin.messaging().sendToDevice(fcmToken, payload);

        console.log("Push sent successfully.");
        return null;
    }
);
