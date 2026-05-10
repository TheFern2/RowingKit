import Foundation

public struct RowingSnapshot: Sendable, Equatable {
    public var elapsedTime: TimeInterval?
    public var distance: Double?
    public var strokeRate: Int?
    public var strokeCount: Int?
    public var pace: TimeInterval?
    public var averagePace: TimeInterval?
    public var speed: Double?
    public var power: Int?
    public var averagePower: Int?
    public var heartRate: Int?
    public var calories: Int?
    public var caloriesPerHour: Int?
    public var caloriesPerMinute: Int?
    public var dragFactor: Int?
    public var driveLength: Double?
    public var driveTime: TimeInterval?
    public var recoveryTime: TimeInterval?
    public var strokeDistance: Double?
    public var peakDriveForce: Double?
    public var avgDriveForce: Double?
    public var workPerStroke: Double?
    public var workoutState: WorkoutState?
    public var rowingState: RowingState?
    public var strokeState: StrokeState?
    public var workoutType: WorkoutType?
    public var ergMachineType: ErgMachineType?
    public var resistanceLevel: Int?
    public var metabolicEquivalent: Double?
    public var remainingTime: TimeInterval?
    public var projectedWorkTime: TimeInterval?
    public var projectedWorkDistance: Double?

    public init(
        elapsedTime: TimeInterval? = nil,
        distance: Double? = nil,
        strokeRate: Int? = nil,
        strokeCount: Int? = nil,
        pace: TimeInterval? = nil,
        averagePace: TimeInterval? = nil,
        speed: Double? = nil,
        power: Int? = nil,
        averagePower: Int? = nil,
        heartRate: Int? = nil,
        calories: Int? = nil,
        caloriesPerHour: Int? = nil,
        caloriesPerMinute: Int? = nil,
        dragFactor: Int? = nil,
        driveLength: Double? = nil,
        driveTime: TimeInterval? = nil,
        recoveryTime: TimeInterval? = nil,
        strokeDistance: Double? = nil,
        peakDriveForce: Double? = nil,
        avgDriveForce: Double? = nil,
        workPerStroke: Double? = nil,
        workoutState: WorkoutState? = nil,
        rowingState: RowingState? = nil,
        strokeState: StrokeState? = nil,
        workoutType: WorkoutType? = nil,
        ergMachineType: ErgMachineType? = nil,
        resistanceLevel: Int? = nil,
        metabolicEquivalent: Double? = nil,
        remainingTime: TimeInterval? = nil,
        projectedWorkTime: TimeInterval? = nil,
        projectedWorkDistance: Double? = nil
    ) {
        self.elapsedTime = elapsedTime
        self.distance = distance
        self.strokeRate = strokeRate
        self.strokeCount = strokeCount
        self.pace = pace
        self.averagePace = averagePace
        self.speed = speed
        self.power = power
        self.averagePower = averagePower
        self.heartRate = heartRate
        self.calories = calories
        self.caloriesPerHour = caloriesPerHour
        self.caloriesPerMinute = caloriesPerMinute
        self.dragFactor = dragFactor
        self.driveLength = driveLength
        self.driveTime = driveTime
        self.recoveryTime = recoveryTime
        self.strokeDistance = strokeDistance
        self.peakDriveForce = peakDriveForce
        self.avgDriveForce = avgDriveForce
        self.workPerStroke = workPerStroke
        self.workoutState = workoutState
        self.rowingState = rowingState
        self.strokeState = strokeState
        self.workoutType = workoutType
        self.ergMachineType = ergMachineType
        self.resistanceLevel = resistanceLevel
        self.metabolicEquivalent = metabolicEquivalent
        self.remainingTime = remainingTime
        self.projectedWorkTime = projectedWorkTime
        self.projectedWorkDistance = projectedWorkDistance
    }
}
