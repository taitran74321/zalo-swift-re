import Foundation

/// Finds directories that SwiftPM copies into the target's resource bundle
/// (`resources: [.copy("JSModules"), .copy("Resources")]`).
///
/// `Bundle.module` alone breaks in a hand-assembled `.app` (its generated accessor
/// looks next to the bundle URL and otherwise at an absolute `.build` path), so the
/// app bundle's `Contents/Resources` is searched first; `scripts/make-app.sh` copies
/// `Olaz_Olaz.bundle` there.
enum ResourceLocator {
    static let resourceBundleName = "Olaz_Olaz.bundle"

    /// `<resource bundle>/<subdirectory>` (e.g. `"JSModules"`, `"Resources"`), or nil.
    static func url(forSubdirectory subdirectory: String) -> URL? {
        let fm = FileManager.default
        // A resource bundle's files sit at its root (flat) or under Contents/Resources (what the swiftbuild backend emits).
        // The paths are checked directly: `Bundle(url:).resourceURL` is not used alone, because a flat bundle that has a
        // top-level `Resources/` folder (ours does: `.copy("Resources")`) is read by Foundation as an old-style bundle whose
        // resource directory is that `Resources/` folder, so `HostScripts/` and `JSModules/` would never be found.
        func roots(ofBundleAt url: URL) -> [URL] {
            guard fm.fileExists(atPath: url.path) else { return [] }
            var out = [url, url.appendingPathComponent("Contents/Resources", isDirectory: true)]
            if let res = Bundle(url: url)?.resourceURL { out.append(res) }
            return out
        }
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL {
            candidates += roots(ofBundleAt: res.appendingPathComponent(resourceBundleName))
            candidates.append(res)
        }
        candidates += roots(ofBundleAt: Bundle.main.bundleURL.appendingPathComponent(resourceBundleName))
        // Next to the executable (`swift run`, `swift test`: .build/<config>/Olaz_Olaz.bundle).
        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            candidates += roots(ofBundleAt: exe.appendingPathComponent(resourceBundleName))
        }
        // Test bundles: .build/<config>/OlazPackageTests.xctest → .build/<config>/Olaz_Olaz.bundle.
        for bundle in Bundle.allBundles where bundle.bundleURL.pathExtension == "xctest" {
            candidates += roots(ofBundleAt: bundle.bundleURL.deletingLastPathComponent().appendingPathComponent(resourceBundleName))
        }
        for base in candidates {
            let url = base.appendingPathComponent(subdirectory, isDirectory: true)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return url
            }
        }
        // Development / `swift test` fallback.
        candidates = roots(ofBundleAt: Bundle.module.bundleURL)
        for base in candidates {
            let url = base.appendingPathComponent(subdirectory, isDirectory: true)
            if fm.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    /// A file inside a resource subdirectory, e.g. `url(for: "vendor/libsignal-protocol.js", in: "JSModules")`.
    static func url(for relativePath: String, in subdirectory: String) -> URL? {
        guard let dir = url(forSubdirectory: subdirectory) else { return nil }
        let url = dir.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
