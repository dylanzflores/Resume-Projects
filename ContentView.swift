import MapKit
import SwiftUI


enum Menu: String, CaseIterable {
    case handshake = "🤝"
    case moon = "🌙"
    case sun = "☀️"
}

struct ContentView: View {
    // Locations
   /* let startPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56, longitude: -3),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )
    Map(initialPosition: startPosition)
*/
    @State private var selection: Menu = .handshake

    var body: some View {
        Map{
            Marker("Las Vegas", coordinate: cityHallLocation)
        }
        NavigationView {
            VStack {
                // Title
                Text("Pinger")
                    .font(.system(size: 130))
                    .padding(.top)

                // Emoji based on selection
                Text(selection.rawValue)
                    .font(.system(size: 150))

                // Horizontal Stack for Menu Tabs (Buttons)
                HStack {
                    ForEach(Menu.allCases, id: \.self) { menuItem in
                        NavigationLink(
                            destination: destinationView(for: menuItem)
                        ) {
                            Text(menuItem.rawValue)
                                .font(.system(size: 50))
                                .padding()
                                .background(selection == menuItem ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("Menu Selection")
        }
    }

    // Function to return the correct view based on the selection
    func destinationView(for menuItem: Menu) -> some View {
        switch menuItem {
        case .handshake:
            return AnyView(HomeView())
        case .moon:
            return AnyView(MoonView())
        case .sun:
            return AnyView(SunView())
        }
    }
}

// Placeholder Views for demonstration
struct HomeView: View {
    var body: some View {
        VStack {
            Text("Home View Content")
                .font(.title)
        }
        .navigationTitle("Handshake View")
    }
}

struct MoonView: View {
    var body: some View {
        ZStack {
            HStack{
                Text("SDKJDGSFKHJD") .font(.system(size: 50))
                Spacer()
            }
            Spacer()
            Text("Moon View Content")
                .font(.title)
        }
        .navigationTitle("Moon View")
    }
}

struct SunView: View {
    var body: some View {
        VStack {
            Text("Sun View Content")
                .font(.title)
        }
        .navigationTitle("Sun View")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
