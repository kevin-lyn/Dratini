import PackageDescription

let package = Package(
    name: "Dratini",
    dependencies: [
        .Package(url: "https://github.com/kevin0571/Ditto.git", majorVersion: 1)
    ],
    exclude: ["Tests"]
)
