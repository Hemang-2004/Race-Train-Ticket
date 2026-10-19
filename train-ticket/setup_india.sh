#!/bin/bash
set -e

# ==============================================================================
# Train-Ticket: Indian Railways Setup & Seeding Script
# Configures Stations, Trains, Routes, Prices, Trips, Users & Contacts
# ==============================================================================

BASE_URL="http://localhost:8088"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}   Train-Ticket: Indian Railways Setup & Seeding     ${NC}"
echo -e "${BLUE}======================================================${NC}"

# ------------------------------------------------------------------------------
# 1. Admin Login & Token Retrieval
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 1] Logging in as Admin (admin / 222222)...${NC}"

ADMIN_RESP=$(curl -s -X POST "${BASE_URL}/api/v1/users/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"222222"}')

ADMIN_TOKEN=$(echo "$ADMIN_RESP" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
  echo "Failed to get admin token! Response: ${ADMIN_RESP}"
  exit 1
fi

echo -e "${GREEN}✓ Admin Token Acquired:${NC} ${ADMIN_TOKEN:0:30}..."

# ------------------------------------------------------------------------------
# 2. Create Indian Stations & Query IDs
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 2] Creating Indian Stations...${NC}"

create_station() {
  local name=$1
  local stay=$2
  
  curl -s -X POST "${BASE_URL}/api/v1/adminbasicservice/adminbasic/stations" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{\"name\":\"${name}\",\"stayTime\":${stay}}" > /dev/null

  local id_res=$(curl -s "${BASE_URL}/api/v1/stationservice/stations/id/${name}")
  local st_id=$(echo "$id_res" | grep -o '"data":"[^"]*' | cut -d'"' -f4)
  
  echo -e "  ${GREEN}✓${NC} Station ${CYAN}${name}${NC} -> ID: ${st_id}"
  echo "$st_id"
}

DELHI_ID=$(create_station "Delhi" 10)
BANGALORE_ID=$(create_station "Bangalore" 10)
MUMBAI_ID=$(create_station "Mumbai" 10)
CHENNAI_ID=$(create_station "Chennai" 8)
KOLKATA_ID=$(create_station "Kolkata" 8)
HYDERABAD_ID=$(create_station "Hyderabad" 7)
AHMEDABAD_ID=$(create_station "Ahmedabad" 6)
PUNE_ID=$(create_station "Pune" 5)
JAIPUR_ID=$(create_station "Jaipur" 5)
BHOPAL_ID=$(create_station "Bhopal" 5)

# ------------------------------------------------------------------------------
# 3. Create Train Types
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 3] Creating Indian Train Types...${NC}"

create_train() {
  local name=$1
  local econ=$2
  local conf=$3
  local speed=$4
  curl -s -X POST "${BASE_URL}/api/v1/adminbasicservice/adminbasic/trains" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{\"name\":\"${name}\",\"economyClass\":${econ},\"confortClass\":${conf},\"averageSpeed\":${speed}}" > /dev/null
  echo -e "  ${GREEN}✓${NC} Train Type: ${CYAN}${name}${NC} (Econ: ${econ}, Confort: ${conf}, Speed: ${speed} km/h)"
}

create_train "VandeBharat" 600 120 160
create_train "Rajdhani" 800 150 140
create_train "Shatabdi" 500 100 130
create_train "Duronto" 700 140 120
create_train "TejasExpress" 550 110 140

# ------------------------------------------------------------------------------
# 4. Create Routes
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 4] Creating Routes...${NC}"

create_route() {
  local start=$1
  local end=$2
  local st_list=$3
  local dist_list=$4
  local label=$5

  local resp=$(curl -s -X POST "${BASE_URL}/api/v1/adminrouteservice/adminroute" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{
      \"startStation\": \"${start}\",
      \"endStation\": \"${end}\",
      \"stationList\": \"${st_list}\",
      \"distanceList\": \"${dist_list}\"
    }")
  
  local rid=$(echo "$resp" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)
  echo -e "  ${GREEN}✓${NC} Route: ${CYAN}${label}${NC} -> ID: ${rid}"
  echo "$rid"
}

ROUTE_DELHI_BLR=$(create_route "${DELHI_ID}" "${BANGALORE_ID}" "${DELHI_ID},${BHOPAL_ID},${HYDERABAD_ID},${BANGALORE_ID}" "0,700,1500,2150" "Delhi -> Bhopal -> Hyderabad -> Bangalore")
ROUTE_MUMBAI_BLR=$(create_route "${MUMBAI_ID}" "${BANGALORE_ID}" "${MUMBAI_ID},${PUNE_ID},${HYDERABAD_ID},${BANGALORE_ID}" "0,150,710,1280" "Mumbai -> Pune -> Hyderabad -> Bangalore")
ROUTE_DELHI_MUMBAI=$(create_route "${DELHI_ID}" "${MUMBAI_ID}" "${DELHI_ID},${JAIPUR_ID},${AHMEDABAD_ID},${MUMBAI_ID}" "0,280,940,1440" "Delhi -> Jaipur -> Ahmedabad -> Mumbai")
ROUTE_KOLKATA_BLR=$(create_route "${KOLKATA_ID}" "${BANGALORE_ID}" "${KOLKATA_ID},${CHENNAI_ID},${BANGALORE_ID}" "0,1650,2000" "Kolkata -> Chennai -> Bangalore")

# ------------------------------------------------------------------------------
# 5. Create Price Configurations
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 5] Creating Price Configurations...${NC}"

create_price() {
  local rid=$1
  local ttype=$2
  local basic=$3
  local first=$4

  curl -s -X POST "${BASE_URL}/api/v1/priceservice/prices" \
    -H "Content-Type: application/json" \
    -d "{
      \"routeId\": \"${rid}\",
      \"trainType\": \"${ttype}\",
      \"basicPriceRate\": ${basic},
      \"firstClassPriceRate\": ${first}
    }" > /dev/null
  echo -e "  ${GREEN}✓${NC} Price: Route (${rid:0:8}...) + ${CYAN}${ttype}${NC}: Basic=${basic}, 1stClass=${first}"
}

create_price "${ROUTE_DELHI_BLR}" "VandeBharat" 0.40 0.80
create_price "${ROUTE_DELHI_BLR}" "Rajdhani" 0.35 0.70
create_price "${ROUTE_MUMBAI_BLR}" "VandeBharat" 0.40 0.80
create_price "${ROUTE_MUMBAI_BLR}" "Rajdhani" 0.35 0.70
create_price "${ROUTE_DELHI_MUMBAI}" "VandeBharat" 0.42 0.85
create_price "${ROUTE_DELHI_MUMBAI}" "TejasExpress" 0.38 0.75
create_price "${ROUTE_KOLKATA_BLR}" "Duronto" 0.32 0.65

# ------------------------------------------------------------------------------
# 6. Create Trips / Travel Schedules
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 6] Creating Trips / Travel Schedules...${NC}"

create_trip() {
  local trip_id=$1
  local ttype=$2
  local rid=$3
  local start_st=$4
  local mid_st=$5
  local end_st=$6
  local start_time=$7
  local end_time=$8

  curl -s -X POST "${BASE_URL}/api/v1/admintravelservice/admintravel" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{
      \"tripId\": \"${trip_id}\",
      \"trainTypeName\": \"${ttype}\",
      \"routeId\": \"${rid}\",
      \"startStationName\": \"${start_st}\",
      \"stationsName\": \"${mid_st}\",
      \"terminalStationName\": \"${end_st}\",
      \"startTime\": \"${start_time}\",
      \"endTime\": \"${end_time}\"
    }" > /dev/null
  echo -e "  ${GREEN}✓${NC} Trip: ${CYAN}${trip_id}${NC} (${ttype}) | Departure: ${start_time:11:5} | Arrival: ${end_time:11:5}"
}

create_trip "G2001" "VandeBharat" "${ROUTE_DELHI_BLR}" "${DELHI_ID}" "${BHOPAL_ID}" "${BANGALORE_ID}" "2026-10-10T06:00:00.000" "2026-10-10T20:30:00.000"
create_trip "D2002" "Rajdhani" "${ROUTE_DELHI_BLR}" "${DELHI_ID}" "${BHOPAL_ID}" "${BANGALORE_ID}" "2026-10-10T16:00:00.000" "2026-10-11T12:00:00.000"
create_trip "G2003" "VandeBharat" "${ROUTE_MUMBAI_BLR}" "${MUMBAI_ID}" "${PUNE_ID}" "${BANGALORE_ID}" "2026-10-10T07:15:00.000" "2026-10-10T18:45:00.000"
create_trip "G2005" "VandeBharat" "${ROUTE_DELHI_MUMBAI}" "${DELHI_ID}" "${JAIPUR_ID}" "${MUMBAI_ID}" "2026-10-10T05:30:00.000" "2026-10-10T17:00:00.000"
create_trip "D2007" "Duronto" "${ROUTE_KOLKATA_BLR}" "${KOLKATA_ID}" "${CHENNAI_ID}" "${BANGALORE_ID}" "2026-10-10T11:00:00.000" "2026-10-11T19:00:00.000"

# ------------------------------------------------------------------------------
# 7. User Registration & Login
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 7] Registering and Logging in Indian Users...${NC}"

curl -s -X POST "${BASE_URL}/api/v1/userservice/users/register" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "rahul_sharma",
    "password": "password123",
    "gender": 1,
    "documentType": 1,
    "documentNum": "987654321012345678",
    "email": "rahul.sharma@example.in"
  }' > /dev/null

RAHUL_LOGIN=$(curl -s -X POST "${BASE_URL}/api/v1/users/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"rahul_sharma","password":"password123"}')

RAHUL_TOKEN=$(echo "$RAHUL_LOGIN" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
RAHUL_USER_ID=$(echo "$RAHUL_LOGIN" | grep -o '"userId":"[^"]*' | cut -d'"' -f4)

echo -e "  ${GREEN}✓${NC} User ${CYAN}rahul_sharma${NC} (ID: ${RAHUL_USER_ID}) logged in."
echo -e "     Token: ${RAHUL_TOKEN:0:30}..."

curl -s -X POST "${BASE_URL}/api/v1/userservice/users/register" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "priya_patel",
    "password": "password123",
    "gender": 2,
    "documentType": 1,
    "documentNum": "123456789098765432",
    "email": "priya.patel@example.in"
  }' > /dev/null

PRIYA_LOGIN=$(curl -s -X POST "${BASE_URL}/api/v1/users/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"priya_patel","password":"password123"}')

PRIYA_USER_ID=$(echo "$PRIYA_LOGIN" | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
echo -e "  ${GREEN}✓${NC} User ${CYAN}priya_patel${NC} (ID: ${PRIYA_USER_ID}) logged in."

# ------------------------------------------------------------------------------
# 8. Add Contacts for Users
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 8] Creating Contacts for User rahul_sharma...${NC}"

if [ -n "$RAHUL_TOKEN" ] && [ -n "$RAHUL_USER_ID" ]; then
  CONTACT_RESP=$(curl -s -X POST "${BASE_URL}/api/v1/contactservice/contacts" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${RAHUL_TOKEN}" \
    -d "{
      \"userId\": \"${RAHUL_USER_ID}\",
      \"name\": \"Rahul Sharma\",
      \"documentType\": 1,
      \"documentNumber\": \"987654321012345678\",
      \"phoneNumber\": \"+91-9876543210\"
    }")
  CONTACT_ID=$(echo "$CONTACT_RESP" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
  echo -e "  ${GREEN}✓${NC} Contact Created: Rahul Sharma (+91-9876543210) [ID: ${CONTACT_ID}]"
fi

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${GREEN}             Setup Completed Successfully!           ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Admin Login:"
echo -e "  Username: ${CYAN}admin${NC} | Password: ${CYAN}222222${NC}"
echo -e "User Logins:"
echo -e "  1. Username: ${CYAN}rahul_sharma${NC} | Password: ${CYAN}password123${NC}"
echo -e "  2. Username: ${CYAN}priya_patel${NC}  | Password: ${CYAN}password123${NC}"
echo -e "Dashboard URL: ${BLUE}http://localhost:8088${NC}"
echo -e "Admin Portal:  ${BLUE}http://localhost:8088/adminlogin.html${NC}"
echo -e "======================================================"
