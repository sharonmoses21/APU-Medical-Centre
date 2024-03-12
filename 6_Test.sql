USE MedicalInfoSystem;
GO

-- Test Case 1: Patient Permissions

-- b. Patients must be able to see all their own personal details only
-- e. Patients must not be able to access other patients’ personal or medication details
EXECUTE AS USER = 'P001'; -- Replace 'PatientUser' with the actual system user id for a patient
SELECT SystemUserID, PName, PPassportNumber, PPhone, PaymentCardNumber, PaymentCardPinCode FROM Patient;
REVERT;

-- c. Patients must be able to update their own details such as passport number, phone, and payment card details only.
EXECUTE AS USER = 'P001';
UPDATE Patient SET PPassportNumber = 'NewPassportNumber', PPhone = 'NewPhoneNumber', PaymentCardNumber = 'NewPaymentDetails'
WHERE SystemUserID = SYSTEM_USER;
SELECT SystemUserID, PName, PPassportNumber, PPhone, PaymentCardNumber, PaymentCardPinCode FROM Patient;
REVERT;

-- d. Patients must be able to check their own medications that was prescribed by their doctor but not change or delete them including past historical data.
-- e. Patients must not be able to access other patients’ personal or medication details
EXECUTE AS USER = 'P001';
SELECT * FROM PatientPrescriptionView
REVERT;

-- f. Patients must not be able to access other details
EXECUTE AS USER = 'P001';
SELECT * FROM Medicine
REVERT;

-- Test Case 2: Nurse Permissions
-- b. Nurses must be able to see all their own personal details only
EXECUTE AS USER = 'N001';
SELECT * FROM StaffView;
REVERT;

-- c. Nurses must be able to update their own details such as passport number and phone only.
EXECUTE AS USER = 'N001';
EXEC dbo.sp_UpdateStaff
    @SPassportNumber = NULL, -- we don't change the passport number
    @SPhone = 'new';
SELECT * FROM StaffView;
REVERT;

-- d. Nurses must be able to check any patient’s medication details but not add, update or delete them including past historical data.
EXECUTE AS USER = 'N001';
SELECT PresDateTime, PName, PPassportNumber, PPhone, SName, SPhone, MName FROM PrescriptionView
REVERT;

-- e. Nurses must be able to check and update any patients’ personal details except for sensitive details
EXECUTE AS USER = 'N001';
SELECT PID, PName, PPhone FROM Patient;
REVERT;

EXECUTE AS USER = 'N001';
UPDATE Patient SET PName = 'NewName', PPhone = 'NewPhoneNumber'
WHERE PID = 1;
SELECT PID, PName, PPhone FROM Patient;
REVERT;

-- Test Case 3: Doctor Permissions
-- b. Doctors must be able to see all their own personal details only
EXECUTE AS USER = 'D001';
SELECT * FROM StaffView;
REVERT;

-- c. Doctor must be able to update their own details such as passport number and phone only.
EXECUTE AS USER = 'D001';
EXEC dbo.sp_UpdateStaff
    @SPassportNumber = 'new',
    @SPhone = NULL; -- not updating the phone number
SELECT * FROM StaffView;
REVERT;

-- h. Doctors must be able to check any patients’ personal details except for sensitive details
EXECUTE AS USER = 'D001';
SELECT PID, PName, PPhone, PPassportNumber FROM Patient;
REVERT;


-- f. Doctors must be able check all patient’s medication details including medications given by other doctors
EXECUTE AS USER = 'D001';
SELECT * FROM PrescriptionView
REVERT;

-- d. Doctors must be able to add new medication details for their patients
EXECUTE AS USER = 'D001';
EXEC dbo.sp_ManagePrescription
    @PresID = NULL, -- Not used for ADD action
    @PatientID = 1, -- The ID of the patient for whom the prescription is being made
    @MedID = 1, -- The ID of the medicine to be prescribed
    @Action = 'ADD';
REVERT;

-- e. Doctors must be able to update or delete medications details that they added
EXECUTE AS USER = 'D001';
EXEC dbo.sp_ManagePrescription
    @PresID = 3, -- The ID of the prescription to update
    @PatientID = 2, -- The ID of the patient for whom the prescription is being made to update
    @MedID = 2, -- The ID of the medicine to be prescribed
    @Action = 'UPDATE';
REVERT;

EXECUTE AS USER = 'D001';
EXEC dbo.sp_ManagePrescription
    @PresID = 3, -- The ID of the prescription to update
    @PatientID = NULL, -- Not used for DELETE action
    @MedID = NULL, -- Not used for DELETE action
    @Action = 'DELETE';
REVERT;

-- g. Doctors must not be able to update or delete medications details added by other doctors
EXECUTE AS USER = 'D001';
EXEC dbo.sp_ManagePrescription
    @PresID = 2, -- The ID of the prescription to delete
    @PatientID = NULL, -- Not used for DELETE action
    @MedID = NULL, -- Not used for DELETE action
    @Action = 'DELETE';
REVERT;

-- i. Doctors must not be able to change or delete any of the patients personal details 
EXECUTE AS USER = 'D001';
UPDATE Patient SET PPhone = 'updated' WHERE PID = 1;
REVERT;
