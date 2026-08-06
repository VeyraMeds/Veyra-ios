import UIKit
import WebKit

class ViewController: UIViewController {
    var webView: WKWebView!
    private var loadView: UIView!
    private var hasLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupLoadingView()
        loadApp()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // Inject app marker at document start — website uses this to hide enrollment/payment flows
        let appMarkerScript = WKUserScript(
            source: "window.isVEYRAApp = true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(appMarkerScript)
        
        config.userContentController = contentController
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.allowsInlineMediaPlayback = true
        config.applicationNameForUserAgent = "VEYRA-APP/1.0 Safari/604.1"

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 8/255, green: 25/255, blue: 79/255, alpha: 1)
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupLoadingView() {
        loadView = UIView(frame: view.bounds)
        loadView.translatesAutoresizingMaskIntoConstraints = false
        loadView.backgroundColor = UIColor(red: 8/255, green: 25/255, blue: 79/255, alpha: 1)

        let logoLabel = UILabel()
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.text = "VEYRA"
        logoLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        loadView.addSubview(logoLabel)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = UIColor(red: 34/255, green: 211/255, blue: 238/255, alpha: 1)
        spinner.startAnimating()
        loadView.addSubview(spinner)

        view.addSubview(loadView)

        NSLayoutConstraint.activate([
            loadView.topAnchor.constraint(equalTo: view.topAnchor),
            loadView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            logoLabel.centerXAnchor.constraint(equalTo: loadView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: loadView.centerYAnchor, constant: -30),
            spinner.centerXAnchor.constraint(equalTo: loadView.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 20)
        ])
    }

    private func loadApp() {
        let url = URL(string: "https://veyrameds.com")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        webView.load(request)
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !hasLoaded {
            hasLoaded = true
            UIView.animate(withDuration: 0.3, animations: {
                self.loadView.alpha = 0
            }) { _ in
                self.loadView.removeFromSuperview()
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if let host = url.host {
                // Allow VEYRA and Base44 (backend API) — block everything else
                if host.contains("veyrameds.com") || host.contains("base44.com") {
                    decisionHandler(.allow)
                    return
                }
                // Redirect Stripe and all external payment URLs to Safari — no in-app payments
                if host.contains("stripe.com") || host.contains("paypal.com") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                    decisionHandler(.cancel)
                    return
                }
                if url.scheme == "tel" || url.scheme == "mailto" {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                    decisionHandler(.cancel)
                    return
                }
                if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
}

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
}
