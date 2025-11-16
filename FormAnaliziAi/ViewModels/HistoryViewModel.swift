//
//  HistoryViewModel.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

@Observable
@MainActor
class HistoryViewModel {
    // Dependencies
    private let storageService: StorageService

    // Published State
    var sessions: [AnalysisSession] = []
    var isLoading = true
    var error: AppError?
    var showError = false

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    // MARK: - Actions
    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sessions = try await storageService.loadAllSessions()
        } catch let appError as AppError {
            error = appError
            showError = true
        } catch {
            self.error = .loadFailed
            showError = true
        }
    }

    func deleteSession(_ session: AnalysisSession) {
        do {
            try storageService.deleteSession(session)
            sessions.removeAll { $0.id == session.id }
        } catch {
            self.error = .deleteFailed
            showError = true
        }
    }

    func refreshSessions() async {
        await loadSessions()
    }
}
