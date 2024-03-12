-- Switch to the MedicalInfoSystem database
USE MedicalInfoSystem;
GO

-- Insert sample data into Staff Table
INSERT INTO Staff (SName, SPassportNumber, SPhone, SystemUserID, Position) VALUES
('Dr. Smith', 'P123456', '012-3456789', 'D001', 'Doctor'),
('Dr. Miller', 'P234567', '012-3456788', 'D002', 'Doctor'),
('Nurse Jane', 'P345678', '012-3456787', 'N001', 'Nurse'),
('Nurse Jake', 'P456789', '012-3456786', 'N002', 'Nurse');
GO

-- Insert sample data into Patient Table
INSERT INTO Patient (PName, PPassportNumber, PPhone, PaymentCardNumber, PaymentCardPinCode, SystemUserID) VALUES
('John Doe', 'P567890', '012-3456785', '1234-5678-9012-3456', '1234', 'P001'),
('Jane Doe', 'P678901', '012-3456784', '2345-6789-0123-4567', '2345', 'P002');
GO

-- Insert sample data into Medicine Table
INSERT INTO Medicine (MName) VALUES
('Paracetamol'),
('Ibuprofen');
GO

-- Insert sample data into Prescription Table
INSERT INTO Prescription (PatientID, DoctorID, MedID, PresDateTime) VALUES
(1, 1, 1, '2023-01-01T10:00:00'),
(2, 2, 2, '2023-01-02T11:00:00');
GO

