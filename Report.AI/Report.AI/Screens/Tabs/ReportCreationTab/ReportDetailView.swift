//
//  InitalScreenView.swift
//  Report.AI
//
//  Created by Nana Bonsu on 9/25/24.
//

import SwiftUI
import CoreLocation

struct ReportDetailView: View {
    @State private var images: [UIImage] = []
    @State private var selectedDate = Date()
    @State private var address = ""
    @State private var descriptionText = ""
    @State private var isPhotoLibraryOpen = false
    @State private var isCameraOpen = false
    @State private var isManualLocation = false
    @State private var manualAddress = ""
    @State private var isManualDescription = false
    
    
    @State private var manualProblemDescription = ""
    @State private var navigateToSolutionView = false
    @State private var solutionText = ""
    @State private var newReport = Report()
    
    @State private var showProgressIndicatorForTextUpdate = false
    
    var problemName: String
    var reportingTo: String
    let maxImages = 3
    @EnvironmentObject var reports: Reports
    @StateObject private var locationManager = LocationManager()
    
    private var currentLocation: String {
        isManualLocation ? manualAddress : locationManager.address
    }
    
    var initialImage: UIImage
    @State var problemDescription: String //the problem being analyzed
    
    @State private var imageToDeleteIndex: Int? = nil
    
    var body: some View {
        
        ZStack {
            if showProgressIndicatorForTextUpdate {
                ActivityIndicator(text: "Updating Problem Description")
                    .zIndex(1)
            }
            ScrollView {
                VStack(spacing: 24) {
                    // Image Gallery Section
                    
                    Text("Reporting to: \(reportingTo)")
                        .fontWeight(.bold)
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle("Photos")
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.accentColor, lineWidth: 1)
                                .background(Color(.systemBackground).cornerRadius(20))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(images.indices, id: \.self) { index in
                                        ImageThumbnail(
                                            image: images[index],
                                            canDelete: index > 0,
                                            onDeleteRequest: {
                                                imageToDeleteIndex = index
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 260)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Add Photo Buttons
                        
                        HStack {
                            Text("\(images.count)/\(maxImages)")
                        }
                        VStack {
                            
                            Text("Include more images in your report by taking a photo or selecting from your gallery")
                            HStack(spacing: 12) {
                                ImageButton(
                                    icon: "photo.on.rectangle.fill",
                                    title: "Gallery",
                                    action: { isPhotoLibraryOpen = true }
                                )
                                .disabled(images.count >= maxImages)
                                ImageButton(
                                    icon: "camera.fill",
                                    title: "Camera",
                                    action: { isCameraOpen = true }
                                )
                                .disabled(images.count >= maxImages)
                            }
                            .padding(.horizontal)
                        }
                    }
                     
                }
                
                // Problem Description
                VStack(alignment: .leading) {
                    SectionTitle("Problem Description")
                    Picker("Description Input", selection: $isManualDescription) {
                        Text("Automatic").tag(false)
                        Text("Manual").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 8)
                    
                    if isManualDescription {
                        ContentCard {
                            TextField("Describe the problem...", text: $manualProblemDescription)
                                .cornerRadius(10)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                        }
                    } else {
                        ContentCard {
                            Text(problemDescription)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                // Location
                VStack(alignment: .leading) {
                    SectionTitle("Location")
                    ContentCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Location Input", selection: $isManualLocation) {
                                Text("Automatic").tag(false)
                                Text("Manual").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.bottom, 8)
                            
                            if isManualLocation {
                                TextField("Enter address manually", text: $manualAddress)
                                    .cornerRadius(10)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.title2)
                                    Text(locationManager.address.isEmpty ? "No location detected" : locationManager.address)
                                        .foregroundColor(.primary)
                                }
                                
                                Button(action: {
                                    locationManager.requestLocation()
                                }) {
                                    Text("Fetch Current Location")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 8)
                            
                       
                            }
                        }
    
                        
                    }
                    .padding()
                }
                
                
                // Date & Time
                VStack(alignment: .leading) {
                    //Chahnge this here!
                    SectionTitle("Date & Time")
                    ContentCard {
                        VStack(alignment: .leading, spacing: 8) {
                            DatePicker("", selection: $selectedDate)
                                .labelsHidden()
                                .accentColor(.accentColor)
                            
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                                Text(selectedDate.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Submit Button
                
                
                FuncttionNavLink(title: "Continue", destination: GeneratedSolutionView(solutionText: solutionText, problemName: problemName, currentReport: newReport)) {  createReport() }
            
                
            }
            .padding()
        }
        
        
        .alert("Remove Image?", isPresented: Binding(
            get: { imageToDeleteIndex != nil },
            set: { if !$0 { imageToDeleteIndex = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                imageToDeleteIndex = nil
            }
            Button("Remove", role: .destructive) {
                if let index = imageToDeleteIndex, images.indices.contains(index) {
                    withAnimation {
                        images.remove(at: index)
                    }
                }
                imageToDeleteIndex = nil
            }
        } message: {
            Text("Removing this image may affect the final result of your report. Are you sure you want to continue?")
        }
        .navigationTitle("\(problemName) Report Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            
            addInitialImage()
            locationManager.requestLocation()
            
            descriptionText = problemDescription
            if(solutionText.isEmpty) {
                Task {
                    //get the solution first
                    solutionText = await GeminiManager.shared.generateSolutionFromProblem(problemDescription: problemDescription)
                }
            }
            
            createReport()
            
        }
        .sheet(isPresented: $isPhotoLibraryOpen) {
            PhotoPicker(images: $images, description: $problemDescription, showLoadingIndicator: $showProgressIndicatorForTextUpdate, updateReport: createReport)
        }
        .sheet(isPresented: $isCameraOpen) {
            CameraPicker(images: $images)
        }
    }
    
    func addInitialImage() {
        if(images.isEmpty) {
            images.append(initialImage)
        }
    }
  
    
    /// converts `UIImage` to a compressed jpeg data that will be shown
    /// - Returns: <#description#>
    func convertImagesToData() -> [Data] {
        
        var dataArray: [Data] = []
        for image in images {
            if let resizedImage = image.resized(to: CGSize(width: 400, height: 400)),
                let imageData = image.jpegData(compressionQuality: 0.7) {
                dataArray.append(imageData)
                }
                
        }
        
        return dataArray
    }
    
    
    func createReport() {
        let imgDataArray = convertImagesToData()
        
        // Get the current location (either manual or automatic)
        let reportLocation = currentLocation
        
        // Create the report with the location
        newReport = Report(
            name: problemName,
            images: imgDataArray,
            description: problemDescription,
            location: reportLocation,
            userReported: User(), reportDestination: reportingTo //  might want to pass the actual user here
        )
        
        newReport.dateReported = selectedDate
        print("Created new report with name: \(newReport.problemName)")
        print("Report Description: \(newReport.problemDescription)")
        print("Report Location: \(newReport.location ?? "No location")")
    }
    
    
    
    struct SectionTitle: View {
        let text: String
        
        init(_ text: String) {
            self.text = text
        }
        
        var body: some View {
            Text(text)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
        }
    }
    
    struct ContentCard<Content: View>: View {
        let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    struct ImageThumbnail: View {
        let image: UIImage
        let canDelete: Bool
        let onDeleteRequest: () -> Void
        
        @State private var isPressed = false
        
        var body: some View {
            ZStack(alignment: .topTrailing) {
                // Image Container
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.accentColor, lineWidth: isPressed ? 2 : 0)
                    )
                    .shadow(color: Color(.systemGray3), radius: isPressed ? 2 : 5, x: 0, y: isPressed ? 1 : 2)
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                
                // Delete Button
                if canDelete {
                    deleteButton
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Report image")
            .accessibilityAddTraits(.isImage)
            .accessibilityHint(canDelete ? "Double tap to preview, swipe up with three fingers to delete" : "Double tap to preview")
        }
        
        private var deleteButton: some View {
            Button(action: {
                hapticFeedback()
                onDeleteRequest()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
            }
            .padding(8)
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel("Delete image")
        }
        
        private func hapticFeedback() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    // Preview
    
    
    struct AddImageButtons: View {
        @Binding var isPhotoLibraryOpen: Bool
        @Binding var isCameraOpen: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                ImageButton(
                    icon: "photo.on.rectangle.fill",
                    title: "Gallery",
                    action: { isPhotoLibraryOpen = true }
                )
                
                ImageButton(
                    icon: "camera.fill",
                    title: "Camera",
                    action: { isCameraOpen = true }
                )
            }
        }
    }
    
    // Supporting view structures remain the same
    struct ImageButton: View {
        let icon: String
        let title: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                    Text(title)
                        .font(.callout)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
    }
    // MARK: - Preview
    
    
    
    
    struct ImageThumbnail_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                ImageThumbnail(image: UIImage(systemName: "photo.fill") ?? UIImage(), canDelete: true) {}
                ImageThumbnail(image: UIImage(systemName: "photo.fill") ?? UIImage(), canDelete: false) {}
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
}

struct ReportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        
            ReportDetailView(
                problemName: "Leaking Faucet",
                reportingTo: "Facilities Manager",
                initialImage: UIImage(systemName: "photo.fill") ?? UIImage(),
                problemDescription: "A faucet is leaking continuously, causing water to overflow. This issue requires immediate attention to avoid water wastage."
            )
            // environment object if needed
           // Provide a mock LocationManager environment object if needed
        
        .previewDisplayName("Report Detail View")
    }
}
