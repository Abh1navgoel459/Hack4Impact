import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var jobTitleSearchText = ""
    @State private var searchResult: String?
    @State private var jobData: [(jobTitle: String, salaryUSD: String)] = []

    // Registration state
    @State private var isRegistrationSheetPresented = false
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search by job title", text: $jobTitleSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .foregroundColor(Color.black) // Set text color to black

                    Button("Submit") {
                        searchJobInCSV()
                    }
                    .padding()
                }

                if let result = searchResult {
                    Text(result)
                        .foregroundColor(result == "Success!" ? .green : .red)
                        .padding()
                }

                List {
                    ForEach(filteredItems()) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }

                // Registration Button
                Button("Register") {
                    isRegistrationSheetPresented.toggle()
                }
                .padding()

                // Registration Sheet
                .sheet(isPresented: $isRegistrationSheetPresented) {
                    registrationSheet
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Now") // Set the app title to "Now"
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(Color.white)
            .onAppear {
                jobData = loadCSVData()
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func filteredItems() -> [Item] {
        var filteredItems = items

        if !jobTitleSearchText.isEmpty {
            filteredItems = filteredItems.filter { item in
                // Add logic to filter items based on job title
                // Example: return item.title.localizedCaseInsensitiveContains(jobTitleSearchText)
                return true // Replace this line with your actual filtering logic
            }
        }

        return filteredItems
    }

    private func searchJobInCSV() {
        let jobFound = jobData.contains { job in
            return job.jobTitle.localizedCaseInsensitiveContains(jobTitleSearchText)
        }

        searchResult = jobFound ? "Success!" : "Job Not Found"
    }

    private func loadCSVData() -> [(jobTitle: String, salaryUSD: String)] {
        guard let csvPath = Bundle.main.path(forResource: "data_professional_salary_survey", ofType: "csv") else {
            return []
        }

        do {
            let csvString = try String(contentsOfFile: csvPath)
            let rows = csvString.components(separatedBy: "\n")
            
            let csvData: [(jobTitle: String, salaryUSD: String)] = rows.dropFirst().compactMap { row in
                let columns = row.components(separatedBy: ",")
                guard columns.count >= 2 else { return nil }
                return (jobTitle: columns[0], salaryUSD: columns[1])
            }

            // Print the loaded CSV data
            print("Loaded CSV Data: \(csvData)")

            return csvData
        } catch {
            print("Error loading CSV: \(error)")
            return []
        }
    }

    // Registration Sheet
    // Registration Sheet
    private var registrationSheet: some View {
        VStack {
            Text("Create an Account")
                .font(.title)
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Register") {
                // Validate password requirements
                guard password.count >= 8, password.rangeOfCharacter(from: .decimalDigits) != nil, password.rangeOfCharacter(from: .uppercaseLetters) != nil else {
                    searchResult = "Password must be at least 8 characters long and contain at least one number and one uppercase letter."
                    return
                }

                // Perform registration logic
                registerUser()
            }
            .foregroundColor(Color.blue) // Set text color to dark blue
            .padding()
        }
        .padding()
    }

    private func registerUser() {
        // Make a POST request to the local PHP file
        print("Registering user")
        let url = URL(string: "http://localhost:8888/NowApp/now.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postString = "username=\(username)&password=\(password)"
        request.httpBody = postString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        if let registrationResult = result["result"] as? String {
                            // Check if registration was successful
                            if registrationResult.lowercased() == "registration successful!" {
                                // Display success message
                                searchResult = "Registered successfully!"
                            } else {
                                // Display the original registration result message
                                searchResult = registrationResult
                            }
                        }
                    }
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: Item.self, inMemory: true)
    }
}

