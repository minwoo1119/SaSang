const fs = require("fs");
const path = require("path");

const googleServicesPlist = "./GoogleService-Info.plist";
const googleServicesJson = "./google-services.json";
const appIdentifier = "com.sasang.app";

function fileExists(relativePath) {
  return fs.existsSync(path.join(__dirname, relativePath));
}

const hasFirebaseConfig =
  fileExists(googleServicesPlist) && fileExists(googleServicesJson);

module.exports = {
  expo: {
    name: "사상",
    slug: "sasang",
    version: "1.0.0",
    orientation: "portrait",
    icon: "./assets/images/icon.png",
    scheme: "sasang",
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
          backgroundColor: "#FFFFFF",
          image: "./assets/images/splash-icon.png",
          imageWidth: 76,
        },
      ],
      ...(hasFirebaseConfig
        ? ["@react-native-firebase/app", "@react-native-firebase/analytics"]
        : []),
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
  },
};
