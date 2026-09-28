import Foundation

enum GameSessionState { case playing, paused, gameOver }

final class GameSession {
    private(set) var state:GameSessionState = .playing
    func pause(){ if state == .playing { state = .paused } }
    func resume(){ if state == .paused { state = .playing } }
    func gameOver(){ state = .gameOver }
    func restart(){ state = .playing }
}
