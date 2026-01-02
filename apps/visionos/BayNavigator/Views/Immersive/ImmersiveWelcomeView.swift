import SwiftUI
import RealityKit

/// An immersive space that creates a welcoming Bay Area-themed environment
/// with floating program category icons arranged in a spatial layout
struct ImmersiveWelcomeView: View {
    @Environment(ProgramsViewModel.self) private var viewModel

    var body: some View {
        RealityView { content in
            // Create a root entity for our scene
            let rootEntity = Entity()

            // Add ambient lighting
            let lightEntity = Entity()
            var lightComponent = PointLightComponent(
                color: .white,
                intensity: 1000,
                attenuationRadius: 10
            )
            lightEntity.components.set(lightComponent)
            lightEntity.position = [0, 2, -2]
            rootEntity.addChild(lightEntity)

            // Create floating category orbs in a circular arrangement
            let categories = [
                ("fork.knife", "Food", UIColor.systemOrange),
                ("heart.text.square.fill", "Health", UIColor.systemRed),
                ("ticket.fill", "Recreation", UIColor.systemPurple),
                ("person.3.fill", "Community", UIColor.systemBlue),
                ("graduationcap.fill", "Education", UIColor.systemIndigo),
                ("dollarsign.circle.fill", "Finance", UIColor.systemGreen),
                ("car.fill", "Transit", UIColor.systemTeal),
                ("house.fill", "Housing", UIColor.systemBrown)
            ]

            let radius: Float = 1.5
            let height: Float = 1.2

            for (index, category) in categories.enumerated() {
                let angle = Float(index) / Float(categories.count) * 2 * .pi
                let x = radius * cos(angle)
                let z = radius * sin(angle) - 2 // Push back from user

                // Create a sphere for each category
                let mesh = MeshResource.generateSphere(radius: 0.15)
                var material = SimpleMaterial()
                material.color = .init(tint: category.2.withAlphaComponent(0.8))
                material.roughness = 0.3
                material.metallic = 0.1

                let sphereEntity = ModelEntity(mesh: mesh, materials: [material])
                sphereEntity.position = [x, height, z]

                // Add a gentle hover animation
                sphereEntity.components.set(HoverComponent(
                    baseHeight: height,
                    amplitude: 0.05,
                    speed: 1.0 + Float(index) * 0.1
                ))

                rootEntity.addChild(sphereEntity)
            }

            // Create a central welcome sphere
            let centerMesh = MeshResource.generateSphere(radius: 0.25)
            var centerMaterial = SimpleMaterial()
            centerMaterial.color = .init(tint: UIColor.systemCyan.withAlphaComponent(0.9))
            centerMaterial.roughness = 0.2
            centerMaterial.metallic = 0.3

            let centerSphere = ModelEntity(mesh: centerMesh, materials: [centerMaterial])
            centerSphere.position = [0, height, -2]
            centerSphere.components.set(HoverComponent(
                baseHeight: height,
                amplitude: 0.08,
                speed: 0.5
            ))

            rootEntity.addChild(centerSphere)

            content.add(rootEntity)
        } update: { content in
            // Update hover animations
            let time = Date().timeIntervalSinceReferenceDate

            for entity in content.entities {
                updateHoverAnimations(entity: entity, time: time)
            }
        }
    }

    private func updateHoverAnimations(entity: Entity, time: TimeInterval) {
        if let hover = entity.components[HoverComponent.self] {
            let offset = sin(Float(time) * hover.speed) * hover.amplitude
            entity.position.y = hover.baseHeight + offset
        }

        for child in entity.children {
            updateHoverAnimations(entity: child, time: time)
        }
    }
}

/// Component for hover animation
struct HoverComponent: Component {
    var baseHeight: Float
    var amplitude: Float
    var speed: Float
}

#Preview(immersionStyle: .mixed) {
    ImmersiveWelcomeView()
        .environment(ProgramsViewModel())
}
