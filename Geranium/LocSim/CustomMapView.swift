//
//  CustomMapView.swift
//  Geranium
//
//  Created by cclerc on 21.12.23.
//

import SwiftUI
import MapKit

struct CustomMapView: UIViewRepresentable {
    @Binding var tappedCoordinate: EquatableCoordinate?
    let defaultRadiusMeters: CLLocationDistance
    let centerRequest: MapCenterRequest?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.layer.cornerRadius = 15
        mapView.layer.masksToBounds = true

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapRecognizer)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applyInitialRegionIfPossible(to: uiView)
        context.coordinator.applyCenterRequestIfNeeded(to: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        private var appliedRadiusMeters: CLLocationDistance?
        private var handledCenterRequestID: UUID?

        init(_ parent: CustomMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            applyInitialRegionIfPossible(to: mapView)
        }

        func applyInitialRegionIfPossible(to mapView: MKMapView) {
            guard let location = mapView.userLocation.location,
                  CLLocationCoordinate2DIsValid(location.coordinate) else { return }

            let radiusMeters = max(100.0, min(parent.defaultRadiusMeters, 1_000_000.0))
            guard appliedRadiusMeters != radiusMeters else { return }

            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: radiusMeters * 2,
                longitudinalMeters: radiusMeters * 2
            )
            mapView.setRegion(region, animated: false)
            appliedRadiusMeters = radiusMeters
        }

        func applyCenterRequestIfNeeded(to mapView: MKMapView) {
            guard let request = parent.centerRequest,
                  request.id != handledCenterRequestID,
                  CLLocationCoordinate2DIsValid(request.coordinate) else { return }

            mapView.setCenter(request.coordinate, animated: true)
            handledCenterRequestID = request.id
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            parent.tappedCoordinate = EquatableCoordinate(coordinate: coordinate)
        }
    }
}

struct MapCenterRequest {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
