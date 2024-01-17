import SwiftUI
import Combine
import Firebase
import FirebaseFirestore

struct HomeView: View {
    
   @State private var shadowColor: Color = .black
   @State private var shadowRadius: CGFloat = 8
   @State private var shadowX: CGFloat = 20
   @State private var shadowY: CGFloat = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue)
                .frame(width: 300, height: 150)
                .offset(x: 0, y: -200)
                .onTapGesture {
                    openGoogleSite()
                }
                .shadow(color: shadowColor, radius: shadowRadius, x: shadowX, y: shadowY)
            
            Image("Me")
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .offset(x: -80, y: -200)
            
            Text("Karolis Kleinauskas")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .offset(x: 55, y: -225)
            
            Text("Klaipėdos valstybinė")
                .offset(x: 55, y: -200)
                .foregroundColor(.white)
            
            Text("kolegija")
                .offset(x: 8, y: -180)
                .foregroundColor(.white)
                .padding()
                .shadow(radius: 5)
                .border(.red, width: 4)
                .background(.white)
            
           Text("I 19-2, 2024")
                .offset(x:25, y: -155)
                .foregroundColor(.white)
            
            Image("Boovie")
                .resizable()
                .frame(width: 300, height: 400)
                .offset(y: 100)
        }
        .onAppear() {
            withAnimation(.linear(duration: 2.5)) {
                shadowColor = Color(.darkGray)
                shadowRadius = 2
                shadowX = -5
                shadowY = 5
            }
            
        }
        
    }

    func openGoogleSite() {
        if let url = URL(string: "https://www.kvk.lt") {
            UIApplication.shared.open(url)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
