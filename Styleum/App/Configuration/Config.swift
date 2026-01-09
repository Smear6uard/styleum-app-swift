import Foundation

enum Config {
    // Supabase - Auth & Storage only
    static let supabaseURL = "https://ldfnbklxxeqhughckeus.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkZm5ia2x4eGVxaHVnaGNrZXVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNzA4MTMsImV4cCI6MjA3OTk0NjgxM30.89LSDBgBn2TAXzroya2_1uBkZLxHpcwDvuiBwaoKsX8"
    static let googleClientID = "642816391624-9f84235tn3aimlhekvo0tcgteh7m5mp2.apps.googleusercontent.com"

    // Hono API Backend
    // static let apiBaseURL = "https://styleum-api-production.up.railway.app"
    static let apiBaseURL = "http://localhost:3001" // Local testing
}
