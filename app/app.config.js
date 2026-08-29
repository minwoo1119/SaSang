const fs = require("fs");
const path = require("path");
const { withDangerousMod } = require("@expo/config-plugins");

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

const hasFirebaseConfig =
  fileExists(googleServicesPlist) && fileExists(googleServicesJson);

function withRNFirebaseDisableSPM(config) {
  return withDangerousMod(config, [
    "ios",
    async (config) => {
      const iosRoot = config.modRequest.platformProjectRoot;
      const podfilePath = path.join(iosRoot, "Podfile");
      if (fs.existsSync(podfilePath)) {
        let content = fs.readFileSync(podfilePath, "utf8");
        if (!content.includes("use_modular_headers!")) {
          content = `ENV['PATH'] = "/bin:/usr/bin:/usr/local/bin:/opt/homebrew/bin:\#{ENV['PATH']}"\nuse_modular_headers!\n$RNFirebaseDisableSPM = true\n\n` + content;
          fs.writeFileSync(podfilePath, content, "utf8");
        } else if (!content.includes("ENV['PATH']")) {
          content = `ENV['PATH'] = "/bin:/usr/bin:/usr/local/bin:/opt/homebrew/bin:\#{ENV['PATH']}"\n` + content;
          fs.writeFileSync(podfilePath, content, "utf8");
        }
      }

      const xcodeEnvPath = path.join(iosRoot, ".xcode.env");
      if (fs.existsSync(xcodeEnvPath)) {
        let envContent = fs.readFileSync(xcodeEnvPath, "utf8");
        if (!envContent.includes("export PATH=")) {
          envContent = `export PATH="/bin:/usr/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"\n` + envContent;
          fs.writeFileSync(xcodeEnvPath, envContent, "utf8");
        }
      }
      return config;
    },
  ]);
}

module.exports = ({ config }) => {
  const baseConfig = {
    ...config,
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
        ? [
            [
              "@react-native-firebase/app",
              {
                disableSPM: true,
              },
            ],
            "@react-native-firebase/analytics",
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
        "expo-build-properties",
        {
          ios: {
            useFrameworks: "static",
          },
        },
      ],
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
    expo: withRNFirebaseDisableSPM(baseConfig),
    "react-native-google-mobile-ads": {
      android_app_id: admobAppIds.android,
      ios_app_id: admobAppIds.ios,
    },
  };
};
