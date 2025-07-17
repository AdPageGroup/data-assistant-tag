___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "AdPage Data Assistant",
  "brand": {
    "id": "brand_dummy",
    "displayName": "",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAABCFBMVEUAAAARKmQRKmQRKmQRKmR5Ojj/TwARKmQRKmSIPDIRKmSFPDMRKmSIPTKMPTBOYIyiq8LGzNrq7PH39/rM0d6krsRLXoqMmLTEytlCVYSPPi8TLGWPm7b///9zgqTZ3eZQY421vc/+/v77/P1RZI4tQ3b6+/yLl7RFWYYYMWk1S3yYo7zKz9zd4ekWLmegqsFTZY/v8fV2hKY4TX4ULWbz9Pdeb5YiOW/c4OloeJ2utspUZpAyR3nn6e+7wtORnLezu874+PoVLWZSZI94hqf09fjl6O7Fy9n9/f68w9M8UICstckqQXRgcZiBjq11g6VIW4gcNGsxRnlNX4shOG4RKmQRKmQRKmSp9aF5AAAAWHRSTlMAOsHy////O/3/vf/z////////////////////////////////////////////////////////////////////////////////////////////////Pvw9QywndwAAAQxJREFUeJy9k1lTwkAQhJcwEkA5FBQUghhAUEAB5T4FQUGUw+v//xOT2ZAyMEne6Jft6v52M9mqZcwhOIHQgYuLiW6qVuTRAK9JD3DIgSNTAHwImPecsATAbwcok/4DAsHjk1D49AwiUVXnGF7oQCwuaUpc4pLk+QaIXW16SU7hkjYC+n5dRiBzbQNkeRjN3dzmSaCAWfFO9fccKBmAMmYV9A8UwAcPoH+UiU9UMauhr1MnNDALom9SQ7b4FbUV2+lSgLZL6vUHT+RvDos2FwWlHWBkBOBZb8YT6gSA3Avmr9PZG5rkNgAwf/9YLFcA609VX7sAqX0A5k8P5WXfP1a9W2Tsl37+qpyCg/0BZ1024DImT68AAAAASUVORK5CYII\u003d"
  },
  "description": "",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "taggingUrl",
    "displayName": "Tagging URL",
    "simpleValueType": true
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const addEventCallback = require("addEventCallback");
const copyFromWindow = require("copyFromWindow");
const setInWindow = require("setInWindow");
const log = require("logToConsole");
const getTimestamp = require("getTimestampMillis");
const sendPixel = require("sendPixel");
const generateRandom = require("generateRandom");
const callInWindow = require("callInWindow");

const DATA_LAYER = "dataLayer";
const UNIQUE_EVENT_ID_COUNT = "AP_UNIQUE_EVENT_ID";
const REQUEST_ID = "AP_REQUEST_ID";
const USER_ID = "AP_USER_ID";
const SESSION_ID = "AP_SESSION_ID";
const REQUEST_QUEUE = "AP_REQUEST_QUEUE";
const EVENTS = [
  "add_payment_info",
  "add_shipping_info",
  "add_to_cart",
  "begin_checkout",
  "purchase",
  "remove_from_cart",
  "view_cart",
  "view_item",
  "view_item_list",
];

const MONITORING_ROUTE = "/_tools/monitoring";

const safeGetRequestId = () => {
  const requestId = copyFromWindow(REQUEST_ID);
  if (requestId === undefined) {
    const randomId = generateRandom(1000000, 9999999);
    setInWindow(REQUEST_ID, randomId);

    return randomId;
  }

  return requestId;
};

const safeGetUserId = () => {
  const requestId = copyFromWindow(USER_ID);
  if (requestId === undefined) {
    const dataLayer = copyFromWindow(DATA_LAYER);
    const filteredEvents = dataLayer.filter(
      (d) => d.event && d.event === "trytagging_user_data"
    );
    const userDataEvent = filteredEvents.length > 0 ? filteredEvents[0] : {};

    if (
      userDataEvent &&
      userDataEvent.marketing &&
      userDataEvent.marketing.user_id
    ) {
      setInWindow(USER_ID, userDataEvent.marketing.user_id, true);
      return userDataEvent.marketing.user_id;
    }

    return null;
  }

  return requestId;
};

const safeGetSessionId = () => {
  const sessionId = copyFromWindow(SESSION_ID);

  if (sessionId === undefined) {
    const dataLayer = copyFromWindow(DATA_LAYER);
    const filteredEvents = dataLayer.filter(
      (d) => d.event && d.event === "trytagging_user_data"
    );
    const userDataEvent = filteredEvents.length > 0 ? filteredEvents[0] : {};

    if (
      userDataEvent &&
      userDataEvent.marketing &&
      userDataEvent.marketing.session_id
    ) {
      setInWindow(SESSION_ID, userDataEvent.marketing.session_id, true);
      return userDataEvent.marketing.session_id;
    }

    return null;
  }

  return sessionId;
};

const fillQueue = (queueItem) => {
  const existingQueue = copyFromWindow(REQUEST_QUEUE);

  if (existingQueue === undefined) {
    setInWindow(REQUEST_QUEUE, [queueItem]);
    return;
  }

  existingQueue.push(queueItem);
  setInWindow(REQUEST_QUEUE, existingQueue, true);
};

const flushQueue = () => {
  setInWindow(REQUEST_QUEUE, [], true);
};

const safeGetUniqueEventId = () => {
  const count = copyFromWindow(UNIQUE_EVENT_ID_COUNT);
  if (count === undefined) {
    setInWindow(UNIQUE_EVENT_ID_COUNT, -2);

    return -2;
  }

  return count;
};

const incrementUniqueEventId = () => {
  let count = safeGetUniqueEventId();
  setInWindow(UNIQUE_EVENT_ID_COUNT, count + 1, true);
};

const getEventName = (eventId, dataLayer) => {
  if (eventId === -2) {
    return { event: "Consent Initialization", "gtm.uniqueEventId": eventId };
  }

  if (eventId === -1) {
    return { event: "Initialization", "gtm.uniqueEventId": eventId };
  }

  if (dataLayer[eventId]) {
    const evt = dataLayer[eventId];

    if (!evt) {
      return { event: "Unknown Event", "gtm.uniqueEventId": eventId };
    }

    return evt;
  }

  return { event: "No Event", "gtm.uniqueEventId": eventId };
};

function isEventIncluded(eventName) {
  for (let i = 0; i < EVENTS.length; i++) {
    if (EVENTS[i] === eventName) {
      return true;
    }
  }
  return false;
}

function shouldPanic(queue) {
  for (const item of queue) {
    const eventName = item.event.event;
    if (!eventName) {
      continue;
    }
    if (eventName === "trytagging_user_data") {
      return false;
    }
    if (isEventIncluded(eventName)) {
      return true;
    }
  }

  return false;
}

const sendEvent = (evt, userId, sessionId) => {
  callInWindow(
    "sendEventDataToApi",
    data.taggingUrl +
      MONITORING_ROUTE +
      "?panic=false&userId=" +
      userId +
      "&sessionId=" +
      sessionId,
    evt
  );
};

const sendPanic = (requestId, userId, timestamp) => {
  const params =
    "?requestId=" + requestId + "&userId=" + userId + "&timestamp=" + timestamp;
  sendPixel(data.taggingUrl + MONITORING_ROUTE + params);
};

addEventCallback(function (ctid, _eventData) {
  log("send request");
  const timestamp = getTimestamp();
  const dataLayer = copyFromWindow(DATA_LAYER);
  const uniqueEventIdCount = safeGetUniqueEventId();
  const userId = safeGetUserId();
  const requestId = safeGetRequestId();
  const sessionId = safeGetSessionId();

  const dataLayerEvent = getEventName(uniqueEventIdCount, dataLayer);
  log(_eventData);
  const tagsInfo = _eventData.tags;
  const evt = {
    tags: tagsInfo,
    event: dataLayerEvent || { event: null },
    requestId: requestId,
    timestamp: timestamp,
    sessionId: sessionId,
    metadata: dataLayer.ecommerce || {},
  };

  const queue = copyFromWindow(REQUEST_QUEUE) || [];

  if (
    userId === null ||
    copyFromWindow("sendEventDataToApi") == null ||
    sessionId === null
  ) {
    fillQueue(evt);
  } else {
    if (queue) {
      queue.forEach((queueItem) => sendEvent(queueItem, userId, sessionId));
    }
    flushQueue();
    sendEvent(evt, userId, sessionId);
  }

  if (shouldPanic(queue)) {
    sendPanic(requestId, userId, timestamp);
    flushQueue();
  }

  if (dataLayerEvent.event !== "No Event") {
    incrementUniqueEventId();
  } else {
    log("Not incrementing due to no event found");
  }
});

data.gtmOnSuccess();


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_metadata",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_pixel",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "dataLayer"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "AP_UNIQUE_EVENT_ID"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "AP_REQUEST_ID"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "AP_REQUEST_QUEUE"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "AP_USER_ID"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "sendEventDataToApi"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "AP_SESSION_ID"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 5/21/2024, 12:56:57 PM
