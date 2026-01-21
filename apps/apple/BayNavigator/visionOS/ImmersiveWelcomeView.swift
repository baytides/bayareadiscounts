#if os(visionOS)
import SwiftUI
import RealityKit
import BayNavigatorCore

struct ImmersiveWelcomeView: View {
    @Environment(ProgramsViewModel.self) private var programsVM

    var body: some View {
        RealityView { content in
            // Create an anchor for our content
            let anchor = AnchorEntity(.head)
            anchor.position = [0, 0, -2] // 2 meters in front of user

            // Add category spheres in an arc
            let categories = [
                ("Food", Color.green, SIMD3<Float>(-1.5, 0.3, -2)),
                ("Housing", Color.blue, SIMD3<Float>(-0.75, 0.5, -2.2)),
                ("Health", Color.red, SIMD3<Float>(0, 0.6, -2.3)),
                ("Employment", Color.orange, SIMD3<Float>(0.75, 0.5, -2.2)),
                ("Education", Color.purple, SIMD3<Float>(1.5, 0.3, -2))
            ]

            for (name, color, position) in categories {
                let sphere = createCategorySphere(name: name, color: color)
                sphere.position = position
                content.add(sphere)
            }

            // Add welcome text
            let welcomeEntity = createWelcomeText()
            welcomeEntity.position = [0, 1.2, -2]
            content.add(welcomeEntity)

            // Add ambient particles
            if let particles = createAmbientParticles() {
                particles.position = [0, 0, -2]
                content.add(particles)
            }

        } update: { content in
            // Handle updates if needed
        }
    }

    private func createCategorySphere(name: String, color: Color) -> Entity {
        let entity = Entity()

        // Create glowing sphere
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(color))
        material.emissiveColor = .init(color: UIColor(color.opacity(0.5)))
        material.emissiveIntensity = 0.3

        let mesh = MeshResource.generateSphere(radius: 0.15)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        // Add subtle hover effect
        modelEntity.components.set(HoverEffectComponent())
        modelEntity.components.set(InputTargetComponent())
        modelEntity.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.15)])

        entity.addChild(modelEntity)

        // Add floating animation
        let animation = OrbitAnimation(
            duration: 4.0,
            axis: [0, 1, 0],
            startTransform: entity.transform,
            bindTarget: .transform
        )
        if let animationResource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(animationResource.repeat())
        }

        return entity
    }

    private func createWelcomeText() -> Entity {
        let textMesh = MeshResource.generateText(
            "Bay Navigator",
            extrusionDepth: 0.02,
            font: .systemFont(ofSize: 0.15, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        var material = SimpleMaterial()
        material.color = .init(tint: .white)

        let textEntity = ModelEntity(mesh: textMesh, materials: [material])
        textEntity.position.x = -textMesh.bounds.extents.x / 2

        let container = Entity()
        container.addChild(textEntity)

        return container
    }

    private func createAmbientParticles() -> Entity? {
        // Create subtle particle system for ambient effect
        var particleEmitter = ParticleEmitterComponent()
        particleEmitter.emitterShape = .sphere
        particleEmitter.emitterShapeSize = [3, 3, 3]
        particleEmitter.birthRate = 20
        particleEmitter.mainEmitter.lifeSpan = 5.0
        particleEmitter.mainEmitter.size = 0.005
        particleEmitter.mainEmitter.color = .constant(.single(.white.withAlphaComponent(0.3)))
        particleEmitter.speed = 0.02

        let entity = Entity()
        entity.components.set(particleEmitter)

        return entity
    }
}

// MARK: - Category Detail View (for selection)

struct CategoryDetailAttachment: View {
    let categoryName: String
    let programCount: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(categoryName)
                .font(.headline)

            Text("\(programCount) programs")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Explore") {
                // Navigation handled by parent
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .glassBackgroundEffect()
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveWelcomeView()
        .environment(ProgramsViewModel())
}
#endif
