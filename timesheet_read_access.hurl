# I want only consultants to be able to see their timesheet

## A consultant can see their timesheet without specifying the consultant query param

GET http://localhost:8788/timesheets?month=2022-04
X-Sqlfe-User-Id: RDA
HTTP/* 200
[Asserts]
jsonpath "$.days['2022-04-01']" == "eat_cakes"
jsonpath "$.days['2022-04-02']" == "race"

## A consultant cannot see the timesheet of another consultant

GET http://localhost:8788/timesheets?consultant=TSP&month=2022-04
X-Sqlfe-User-Id: RDA
HTTP/* 400
