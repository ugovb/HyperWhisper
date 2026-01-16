import Foundation
import Security

public enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidItemFormat
    case unexpectedData
}

/// Helper for managing secure items in the Keychain.
public final class KeychainService: Sendable {
    public static let shared = KeychainService()
    
    // Service identifier for HyperWhisper
    private let service = "com.hyperwhisper.api-keys"
    
    private init() {}
    
    /// Saves a string to the Keychain.
    /// - Parameters:
    ///   - key: The secret value (e.g., API Key).
    ///   - account: The account name (e.g., "openai").
    public func save(_ key: String, for account: String) throws {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete if exists first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Retrieves a string from the Keychain.
    /// - Parameter account: The account name (e.g., "openai").
    public func retrieve(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
        
        guard let data = item as? Data, let result = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return result
    }
    
    /// Deletes an item from the Keychain.
    public func delete(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}
