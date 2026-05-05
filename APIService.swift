
// Services/APIService.swift
import Foundation

// MARK: - Base URL
enum APIConfig {
    static let baseURL = "http://localhost:8000/api"
}

// MARK: - HTTP Errors
enum APIError: LocalizedError {
    case invalidURL, noData, decodingError(String), serverError(String), unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "Invalid URL"
        case .noData:             return "No data received"
        case .decodingError(let m): return "Decode error: \(m)"
        case .serverError(let m): return m
        case .unauthorized:       return "Session expired. Please login again."
        }
    }
}

// MARK: - Response wrapper
struct APIResponse<T: Decodable>: Decodable {
    let detail: String?
}

// MARK: - APIService
final class APIService {
    static let shared = APIService()
    private init() {}

    private var token: String? {
        UserDefaults.standard.string(forKey: "auth_token")
    }

    // ── Generic request ──────────────────────────────────────────
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw APIError.unauthorized
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "Server error"
            throw APIError.serverError(msg)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // ── Multipart upload (complaints with evidence) ───────────────
    func submitComplaint(form: ComplaintForm, evidenceData: Data?, evidenceMime: String?) async throws -> String {
        guard let url = URL(string: APIConfig.baseURL + "/complaints/submit") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        var body = Data()
        func append(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        append("category_id",    "\(form.categoryId)")
        append("subcategory_id", "\(form.subcategoryId)")
        append("location",       form.location)
        append("description",    form.description)
        append("incident_date",  ISO8601DateFormatter().string(from: form.incidentDate))

        for (name, reg) in zip(form.involvedNames, form.involvedRegs) {
            append("involved_names", name)
            append("involved_regs",  reg)
        }

        if let data = evidenceData, let mime = evidenceMime {
            let ext = mime.contains("video") ? "mp4" : "jpg"
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"evidence\"; filename=\"evidence.\(ext)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (respData, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode([String: String].self, from: respData))?["detail"] ?? "Upload failed"
            throw APIError.serverError(msg)
        }
        return "Complaint submitted successfully"
    }
}
