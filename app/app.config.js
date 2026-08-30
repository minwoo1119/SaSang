const fs = require("fs");
const path = require("path");

const googleServicesPlist = "./GoogleService-Info.plist";
const googleServicesJson = "./google-services.json";
const appIdentifier = "com.sasang.app";
const admobAppIds = {
  android: "ca-app-pub-6638972080325593~4249870188",
  ios: "ca-app-pub-6638972080325593~4398983341",
};

function fileExists(relativePath) {
  return fs.existsSync(path.join(__dirname, relativePath));
}

const hasFirebaseConfig = false;

module.exports = ({ config }) => {
  const baseConfig = {
    ...config,
    name: "사상",
    slug: "sasang",
    version: "1.0.0",
    orientation: "portrait",
    icon: "./assets/images/icon.png",
    scheme: "sasang",
    extra: {
      eas: {
        projectId: "61d86d82-2904-4975-bb79-7bdabb61f81a",
      },
    },
    userInterfaceStyle: "automatic",
    ios: {
      bundleIdentifier: appIdentifier,
      icon: "./assets/images/icon.png",
      ...(hasFirebaseConfig
        ? { googleServicesFile: googleServicesPlist }
        : {}),
    },
    android: {
      adaptiveIcon: {
        backgroundColor: "#FFFFFF",
        foregroundImage: "./assets/images/android-icon-foreground.png",
      },
      package: appIdentifier,
      ...(hasFirebaseConfig
        ? { googleServicesFile: googleServicesJson }
        : {}),
      predictiveBackGestureEnabled: false,
    },
    web: {
      output: "static",
      favicon: "./assets/images/favicon.png",
    },
    plugins: [
      "expo-router",
      [
        "expo-splash-screen",
        {
          backgroundColor: "#FAFAFA",
          image: "./assets/images/main-text-design.png",
          imageWidth: 220,
          resizeMode: "contain",
        },
      ],
      ...(hasFirebaseConfig
        ? [
            [
              "@react-native-firebase/app",
              {
                disableSPM: true,
              },
            ],
          ]
        : []),
      [
        "react-native-google-mobile-ads",
        {
          androidAppId: admobAppIds.android,
          iosAppId: admobAppIds.ios,
          userTrackingUsageDescription:
            "맞춤형 광고 제공을 위해 기기 식별자가 사용될 수 있습니다.",
        },
      ],
      "expo-font",
      "expo-web-browser",
      [
        "expo-image-picker",
        {
          photosPermission:
            "여행 사진을 선택하여 지역 지도에 표시하기 위해 사진 보관함 접근이 필요합니다.",
          cameraPermission: false,
          microphonePermission: false,
        },
      ],
    ],
    experiments: {
      typedRoutes: true,
      reactCompiler: true,
    },
  };

  return {
    expo: baseConfig,
    "react-native-google-mobile-ads": {
      android_app_id: admobAppIds.android,
      ios_app_id: admobAppIds.ios,
    },
  };
};
