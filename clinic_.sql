use embu_clinic;
SELECT * FROM embu_clinic.admissions;
SELECT * FROM embu_clinic.patients;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- List all patients from the "Runyenjes" sub-county, ordered by registration date.
select*from embu_clinic.patients where sub_county in ('Runyenjes') order by registration_date;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Find all staff members with the role "Doctor", showing name, department, and license number.
SELECT role, concat(first_name,' ',last_name) as name,license_number,department_id FROM embu_clinic.staff where role='Doctor';

----------------------------------------------------------------------------------------------------------------------------------------------------

-- How many appointments have a status of "No-show"?
SELECT *,count(*) over() FROM embu_clinic.appointments where status='No-show' ;
SELECT count(status) FROM embu_clinic.appointments where status='No-show';
----------------------------------------------------------------------------------------------------------------------------------------------------

-- List all medications in the "Antibiotic" category, ordered by unit price descending.
SELECT * FROM embu_clinic.medications where category='Antibiotic' order by unit_price desc ;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Find all admissions that are still ongoing (no discharge date).
SELECT * FROM embu_clinic.admissions where discharge_date is null ;
----------------------------------------------------------------------------------------------------------------------------------------------------
  
-- What is the average price of a lab test, grouped by category?
SELECT * FROM embu_clinic.lab_tests ;
SELECT category ,avg(price) as Avg_price FROM embu_clinic.lab_tests group by category;
SELECT category ,round(avg(price),0) as Avg_price FROM embu_clinic.lab_tests group by category;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- List each department along with the number of staff assigned to it.
SELECT * FROM embu_clinic.departments ;
SELECT * FROM embu_clinic.staff ;
SELECT c1.name, count(*) staff FROM embu_clinic.departments c1 left join embu_clinic.staff c2 on c1.department_id=c2.department_id group by c1.name;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- For each patient, count how many visits they've had — show only patients with 3+ visits.
SELECT * FROM embu_clinic.visits ;
SELECT patient_id,count(*) n_count FROM embu_clinic.visits group by patient_id having n_count>=3 order by n_count  desc;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Which diagnosis (ICD code + description) appears most frequently across all visits?
SELECT * FROM embu_clinic.diagnoses ;
SELECT icd_code,description,count(*) `count` FROM embu_clinic.diagnoses group by icd_code,description order by `count` desc ;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Show total invoice amount billed per month across 2025.
SELECT * FROM embu_clinic.invoices ;
SELECT month(invoice_date) `month`, SUM(total_amount) AS total_billed
FROM invoices WHERE invoice_date >= '2025-01-01' AND invoice_date < '2026-01-01'
GROUP BY `month` ORDER BY `month`;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- List the top 5 most-prescribed medications by total quantity dispensed.
select * from prescriptions;
select * from medications;

select m.`name`,count(*) as n,sum(m1.quantity) total from medications m 
left join prescriptions m1 on m.medication_id=m1.medication_id 
group by `name` order by sum(m1.quantity) desc limit 5;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- For each insurance provider, count how many patients currently hold an active policy (`valid_to` >= today's simulated "now", e.g. '2026-08-01').
SELECT * FROM embu_clinic.insurance_providers ;
SELECT * FROM embu_clinic.patient_insurance ;

SELECT p.name,count(*) 
FROM embu_clinic.insurance_providers p left join embu_clinic.patient_insurance p1 on p.provider_id=p1.provider_id
where p1.valid_to >='2026-08-01'
group by p.name;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Find all visits where a lab test was ordered but the diagnosis was never recorded.
SELECT * FROM embu_clinic.visits ;
SELECT * FROM embu_clinic.diagnoses ;

SELECT v.visit_id ,v.visit_date
FROM embu_clinic.visits v 
left join embu_clinic.diagnoses v1 on v.visit_id=v1.visit_id where v1.diagnosis_id is null order by v.visit_id;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- What percentage of appointments end up as "Completed" vs other statuses?
select * from appointments;
select `status`,count(*)*100/(select count(*) from appointments) pct from appointments group by status;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Rank staff by number of visits handled, using a window function, partitioned by department.
select * from visits;
select * from staff;

select s.staff_id,s.first_name,s.last_name ,s.department_id, count(v.visit_id) as n_visits, 
 rank() over(partition by s.department_id order by count(v.visit_id)) as dept_rank
from staff s left join visits v on s.staff_id=v.staff_id group by s.staff_id;
----------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------

-- Identify patients who have an active chronic diagnosis (`is_chronic = 1`) but no prescription recorded for any visit tied to that diagnosis.

select*from diagnoses;
select*from visits;

SELECT DISTINCT v.patient_id
FROM diagnoses d JOIN visits v ON d.visit_id = v.visit_id
WHERE d.is_chronic = 1
AND NOT EXISTS (
    SELECT 1 FROM prescriptions pr WHERE pr.visit_id = d.visit_id
);
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Using a CTE, compute the total revenue collected (from `payments`) per department (via visits → invoices → payments).
SELECT * FROM payments ;
SELECT * FROM invoices ;
SELECT * FROM visits ;
with CTE_total as(
select d.`name`, i.total_amount,i.`status`,p.amount,v.department_id from invoices i join payments p on i.invoice_id=p.invoice_id
join visits v on v.visit_id=i.visit_id join departments d on d.department_id=v.department_id
)
select `name`,sum(amount) Total from CTE_total  group by department_id;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- For each invoice, compute the outstanding balance (`total_amount` − sum of payments) and list the 10 largest outstanding balances.
SELECT * FROM invoices ;
SELECT * FROM payments ;
SELECT i.invoice_id, i.total_amount,coalesce(sum(p.amount),0) as paid,
i.total_amount-coalesce(sum(p.amount),0) as balance
 FROM invoices i left join payments p on p.invoice_id=i.invoice_id 
 group by i.invoice_id order by balance desc;


----------------------------------------------------------------------------------------------------------------------------------------------------

-- List the 5 most recently hired nurses, with their hire dates.
SELECT * FROM embu_clinic.staff ;
SELECT* FROM embu_clinic.staff where role='Nurse' order by hire_date desc limit 5;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- Find all lab tests with a turnaround time of 2 hours or less, ordered by price (highest first) , rank them.
SELECT * FROM embu_clinic.lab_tests ;
SELECT * FROM embu_clinic.lab_tests where turnaround_hours<=2 order by price desc ;
select*,row_number()  over() `rank` from(
SELECT * FROM embu_clinic.lab_tests where turnaround_hours<=2 order by price desc )t;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- How many invoices are currently "Unpaid", and what's the total value of those unpaid invoices?
SELECT * FROM embu_clinic.invoices ;
SELECT *,count(*) over() n_count,sum(total_amount) over() total FROM embu_clinic.invoices where status='unpaid' ;
SELECT count(*),sum(total_amount) FROM embu_clinic.invoices where status='unpaid';

-- List the 3 wards with the largest bed capacity.
SELECT * FROM embu_clinic.wards ;
SELECT * FROM embu_clinic.wards order by capacity desc limit 3 ;

-- Count patients by sub-county, ordered from most to fewest.
SELECT * FROM embu_clinic.patients ;
SELECT sub_county, count(*)  FROM embu_clinic.patients group by sub_county order by count(*) desc ;
