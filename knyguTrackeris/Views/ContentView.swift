import SwiftUI
import Combine
import Firebase
import FirebaseFirestore

struct Book: Identifiable, Equatable {
    var id = UUID()
    var authorName: String
    var bookName: String
    var totalPages: Int
    var readPages: Int
    var review: Int
    var isCompleted: Bool
    var category: String

    static let categories = ["Fiction", "Thriller", "Novel", "Romance", "Fantasy", "Mystery", "Horror", "Self-Improvement", "Psychology"]
}

class BookData: ObservableObject {
    @Published var books: [Book] = []

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        loadBooksFromFirestore()
        setupFirestoreListener()
    }

    func addBook(_ book: Book) {
        books.append(book)
        addBookToFirestore(book)
    }

    func toggleCompletion(for book: Book) {
        if let index = books.firstIndex(of: book) {
            books[index].isCompleted.toggle()
            updateBookInFirestore(books[index])
        }
    }

    func deleteBook(at index: Int) {
        let deletedBook = books.remove(at: index)
        deleteBookFromFirestore(deletedBook)
    }

    internal func updateBookInFirestore(_ book: Book) {
        let bookRef = db.collection("books").document(book.id.uuidString)
        let bookData: [String: Any] = [
            "authorName": book.authorName,
            "bookName": book.bookName,
            "totalPages": book.totalPages,
            "readPages": book.readPages,
            "review": book.review,
            "isCompleted": book.isCompleted,
            "category": book.category
        ]

        bookRef.setData(bookData) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document updated")
            }
        }
    }


    private func deleteBookFromFirestore(_ book: Book) {
        let bookRef = db.collection("books").document(book.id.uuidString)

        bookRef.delete { error in
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                print("Document deleted")
            }
        }
    }

    private func addBookToFirestore(_ book: Book) {
        let bookRef = db.collection("books").document(book.id.uuidString)
        let bookData: [String: Any] = [
            "authorName": book.authorName,
            "bookName": book.bookName,
            "totalPages": book.totalPages,
            "readPages": book.readPages,
            "review": book.review,
            "isCompleted": book.isCompleted,
            "category": book.category
        ]

        bookRef.setData(bookData) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added")
            }
        }
    }

    private func loadBooksFromFirestore() {
        db.collection("books").getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.books = querySnapshot?.documents.compactMap { document in
                    if let bookData = document.data() as? [String: Any],
                       let authorName = bookData["authorName"] as? String,
                       let bookName = bookData["bookName"] as? String,
                       let totalPages = bookData["totalPages"] as? Int,
                       let readPages = bookData["readPages"] as? Int,
                       let review = bookData["review"] as? Int,
                       let isCompleted = bookData["isCompleted"] as? Bool,
                       let category = bookData["category"] as? String {
                        return Book(
                            id: UUID(uuidString: document.documentID) ?? UUID(),
                            authorName: authorName,
                            bookName: bookName,
                            totalPages: totalPages,
                            readPages: readPages,
                            review: review,
                            isCompleted: isCompleted,
                            category: category
                        )
                    }
                    return nil
                } ?? []
            }
        }
    }

    private func setupFirestoreListener() {
        listener = db.collection("books").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error ?? NSError())")
                return
            }

            self.books = documents.compactMap { document in
                if let bookData = document.data() as? [String: Any],
                   let authorName = bookData["authorName"] as? String,
                   let bookName = bookData["bookName"] as? String,
                   let totalPages = bookData["totalPages"] as? Int,
                   let readPages = bookData["readPages"] as? Int,
                   let review = bookData["review"] as? Int,
                   let isCompleted = bookData["isCompleted"] as? Bool,
                   let category = bookData["category"] as? String {
                    return Book(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        authorName: authorName,
                        bookName: bookName,
                        totalPages: totalPages,
                        readPages: readPages,
                        review: review,
                        isCompleted: isCompleted,
                        category: category
                    )
                }
                return nil
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject var bookData = BookData()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            NavigationView {
                BookView(bookData: bookData)
            }
            .tabItem {
                Label("Books", systemImage: "book.fill")
            }
            .tag(1)

            NavigationView {
                StatisticsView(bookData: bookData)
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar.fill")
            }
            .tag(2)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StatisticsView: View {
    @ObservedObject var bookData: BookData

    var body: some View {
        VStack {
            Text("Authors You Read the Most")

            // Display a bar chart for authors
            BarChart(data: calculateTopAuthors(), color: .blue)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)

            Text("Categories You Read the Most")

            // Display a bar chart for categories
            BarChart(data: calculateTopCategories(), color: .green)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)

            Spacer()
        }
        .padding()
        .navigationBarTitle("Recommend")
    }

    private func calculateTopAuthors() -> [String: Int] {
        var authorFrequency: [String: Int] = [:]

        
        for book in bookData.books {
            if let count = authorFrequency[book.authorName] {
                authorFrequency[book.authorName] = count + 1
            } else {
                authorFrequency[book.authorName] = 1
            }
        }

        
        let topAuthors = authorFrequency.sorted { $0.value > $1.value }.prefix(5)

        
        var topAuthorsDict: [String: Int] = [:]
        for (author, count) in topAuthors {
            topAuthorsDict[author] = count
        }

        return topAuthorsDict
    }

    private func calculateTopCategories() -> [String: Int] {
        var categoryFrequency: [String: Int] = [:]

        
        for book in bookData.books {
            if let count = categoryFrequency[book.category] {
                categoryFrequency[book.category] = count + 1
            } else {
                categoryFrequency[book.category] = 1
            }
        }

        
        let topCategories = categoryFrequency.sorted { $0.value > $1.value }.prefix(5)

        
        var topCategoriesDict: [String: Int] = [:]
        for (category, count) in topCategories {
            topCategoriesDict[category] = count
        }

        return topCategoriesDict
    }
}




struct BarChart: View {
    let data: [String: Int]
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ForEach(data.sorted { $0.value > $1.value }, id: \.key) { label, count in
                VStack {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .fill(color)
                        .frame(width: 30, height: CGFloat(count) * 10)
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}


struct BookView: View {
    @ObservedObject var bookData = BookData()
    @State private var isFormPresented = false
    @State private var isFilterOptionsVisible = false
    @State private var isCategoryOptionsVisible = false
    @State private var selectedAuthor: String?
    @State private var selectedBook: Book?
    @State private var selectedCategories: Set<String> = Set(Book.categories)

    var body: some View {
        VStack {
            HStack {
                Button(action: { isFormPresented.toggle() }) {
                    HStack {
                        Text("Add")
                            .padding()
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.blue)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .sheet(isPresented: $isFormPresented) {
                    AddBookView(bookData: bookData, isFormPresented: $isFormPresented)
                }

                Button(action: {
                    isFilterOptionsVisible.toggle()
                }) {
                    Text("Filter")
                        .padding()
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .actionSheet(isPresented: $isFilterOptionsVisible) {
                    ActionSheet(
                        title: Text("Filter Options"),
                        buttons: [
                            .default(Text("Show All")) {
                                selectedAuthor = nil
                                selectedCategories = Set(Book.categories)
                            },
                            .cancel()
                        ] + authorsFilterButtons()
                    )
                }

                Button(action: {
                    isCategoryOptionsVisible.toggle()
                }) {
                    Text("Categories")
                        .padding()
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .actionSheet(isPresented: $isCategoryOptionsVisible) {
                    ActionSheet(
                        title: Text("Category Options"),
                        buttons: categoryFilterButtons()
                    )
                }
                
                Spacer()
            }

            List {
                ForEach(bookData.books.filter {
                    (selectedAuthor == nil || $0.authorName == selectedAuthor) &&
                    selectedCategories.contains($0.category)
                }) { book in
                    NavigationLink(destination: BookDetailsView(book: book, bookData: bookData)) {
                        HStack {
                            if book.isCompleted {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .padding(.trailing, 8)
                            }

                            VStack(alignment: .leading) {
                                Text(book.bookName)
                                    .font(.headline)
                                Text(book.authorName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            if let percentage = book.readingProgress {
                                Text("\(percentage)% Read")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .contextMenu {
                        Button(action: {
                            selectedBook = book
                        }) {
                            Text("Edit")
                            Image(systemName: "pencil")
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        bookData.deleteBook(at: index)
                    }
                }
            }
            .listStyle(InsetListStyle())
            .sheet(item: $selectedBook) { book in
                EditBookView(bookData: bookData, isEditing: $isFormPresented, editedBook: book)
            }
        }
        .navigationBarTitle("Book List")
    }

    private func categoryFilterButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Show All")) {
            selectedAuthor = nil
            selectedCategories = Set(Book.categories)
        })

        for category in Book.categories {
            buttons.append(.default(Text("Show \(category)")) {
                selectedAuthor = nil
                selectedCategories = [category]
            })
        }

        return buttons
    }



    private func authorsFilterButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        let authors = Set(bookData.books.map { $0.authorName })
        for author in authors {
            buttons.append(.default(Text("Show \(author)")) {
                selectedAuthor = author
                selectedCategories = Set(Book.categories)
            })
        }

        return buttons
    }
}




struct BookDetailsView: View {
    var book: Book
    @ObservedObject var bookData: BookData
    @State private var isEditing = false

    var body: some View {
        Form {
            Section(header: Text("Book Details")) {
                Text("Author's Name: \(book.authorName)")
                Text("Book's Name: \(book.bookName)")
                Text("Total Pages: \(book.totalPages)")
                Text("Read Pages: \(book.readPages)")
                Text("Review: \(book.review)")
                Text("Status: \(book.isCompleted ? "Completed" : "In Progress")")
                Text("Category: \(book.category)")
            }

            Section {
                Button(action: {
                    toggleCompletion()
                }) {
                    Text(book.isCompleted ? "Mark as In Progress" : "Mark as Completed")
                        .foregroundColor(book.isCompleted ? .red : .green)
                }

                Button(action: {
                    isEditing = true
                }) {
                    Text("Change")
                }
                .sheet(isPresented: $isEditing) {
                    EditBookView(bookData: bookData, isEditing: $isEditing, editedBook: book)
                }
            }
        }
        .navigationBarTitle(book.bookName)
    }

    private func toggleCompletion() {
        bookData.toggleCompletion(for: book)
    }
}


struct EditBookView: View {
    @ObservedObject var bookData: BookData
    @Binding var isEditing: Bool
    @State private var editedBook: Book

    init(bookData: BookData, isEditing: Binding<Bool>, editedBook: Book) {
        self.bookData = bookData
        _isEditing = isEditing
        _editedBook = State(initialValue: editedBook)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Book Details")) {
                    TextField("Author's Name", text: $editedBook.authorName)
                    TextField("Book's Name", text: $editedBook.bookName)
                    TextField("Total Pages", text: Binding<String>(
                        get: { String(self.editedBook.totalPages) },
                        set: { if let newValue = Int($0) { self.editedBook.totalPages = newValue } }
                    ))
                    .keyboardType(.numberPad)
                    TextField("Read Pages", text: Binding<String>(
                        get: { String(self.editedBook.readPages) },
                        set: { if let newValue = Int($0) { self.editedBook.readPages = newValue } }
                    ))
                    .keyboardType(.numberPad)
                    Stepper(value: $editedBook.review, in: 1...5) {
                        Text("Review: \(editedBook.review)")
                    }
                    Toggle("Completed", isOn: $editedBook.isCompleted)
                    Picker("Category", selection: $editedBook.category) {
                        ForEach(0..<Book.categories.count) {
                            Text(Book.categories[$0])
                        }
                    }
                }

                Section {
                    Button(action: {
                        saveChanges()
                    }) {
                        Text("Save Changes")
                    }
                }
            }
            .navigationBarTitle("Edit Book")
            .navigationBarItems(trailing: Button("Cancel") {
                isEditing = false
            })
        }
    }

    private func saveChanges() {
        bookData.updateBookInFirestore(editedBook)
        isEditing = false
    }
}


struct AddBookView: View {
    @ObservedObject var bookData: BookData
    @Binding var isFormPresented: Bool
    @State private var authorName = ""
    @State private var bookName = ""
    @State private var totalPages = ""
    @State private var readPages = ""
    @State private var review = 3
    @State private var isCompleted = false
    @State private var selectedCategoryIndex = 0
    @State private var selectedCategory: String = Book.categories.first ?? ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("Author's Name", text: $authorName)
                    TextField("Book's Name", text: $bookName)
                    TextField("Total Pages", text: Binding<String>(
                        get: { self.totalPages },
                        set: { if let newValue = Int($0) { self.totalPages = String(newValue) } }
                    ))
                    .keyboardType(.numberPad)
                    TextField("Read Pages", text: Binding<String>(
                        get: { self.readPages },
                        set: { if let newValue = Int($0) { self.readPages = String(newValue) } }
                    ))
                    .keyboardType(.numberPad)
                    Stepper(value: $review, in: 1...5) {
                        Text("Review: \(review)")
                    }
                    Toggle("Completed", isOn: $isCompleted)
                    Picker("Category", selection: $selectedCategoryIndex) {
                        ForEach(0..<Book.categories.count) { index in
                            Text(Book.categories[index]).tag(index)
                        }
                    }

                }

                Section {
                    Button(action: {
                        saveBook()
                    }) {
                        Text("Save")
                    }
                    .disabled(!isInputValid())
                }
            }
            .navigationBarTitle("Add Book")
            .navigationBarItems(trailing: Button("Cancel") {
                isFormPresented = false
            })
        }
    }

    private func isInputValid() -> Bool {
        !authorName.isEmpty && !bookName.isEmpty && totalPages.isNumeric && readPages.isNumeric
    }

    private func saveBook() {
        guard let totalPages = Int(totalPages),
              let readPages = Int(readPages) else {
            return
        }

        let newBook = Book(
            authorName: authorName,
            bookName: bookName,
            totalPages: totalPages,
            readPages: readPages,
            review: review,
            isCompleted: isCompleted,
            category: Book.categories[selectedCategoryIndex]
        )

        bookData.addBook(newBook)
        isFormPresented = false
    }
}



extension String {
    var isNumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Book {
    var readingProgress: Int? {
        guard totalPages > 0 else { return nil }
        return (readPages * 100) / totalPages
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


