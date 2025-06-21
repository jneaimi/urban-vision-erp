#!/bin/bash

# Urban Vision ERP - RBAC Setup Script
# This script sets up the modern Directus v11+ Role-Based Access Control system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DIRECTUS_URL="http://localhost:8055"
ADMIN_EMAIL="admin@urbanvision.com"
ADMIN_PASSWORD="urbanvision123"

echo -e "${BLUE}🚀 Urban Vision ERP - RBAC Setup${NC}"
echo "=================================="

# Function to make API calls
make_api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ "$method" = "POST" ]; then
        curl -s -X POST "${DIRECTUS_URL}${endpoint}" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X GET "${DIRECTUS_URL}${endpoint}" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}"
    fi
}

# Step 1: Authenticate and get access token
echo -e "${YELLOW}Step 1: Authenticating...${NC}"

AUTH_RESPONSE=$(curl -s -X POST "${DIRECTUS_URL}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"${ADMIN_EMAIL}\",
        \"password\": \"${ADMIN_PASSWORD}\"
    }")

ACCESS_TOKEN=$(echo $AUTH_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}❌ Authentication failed. Check your credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authentication successful${NC}"

# Step 2: Create Access Policies
echo -e "${YELLOW}Step 2: Creating Access Policies...${NC}"

# 2.1 Sales Operations Policy
echo "Creating Sales Operations Policy..."
SALES_POLICY_RESPONSE=$(make_api_call "POST" "/policies" '{
    "name": "Sales Operations Access",
    "icon": "trending_up",
    "description": "Access to leads, customers, and communication management",
    "ip_access": [],
    "enforce_tfa": false,
    "admin_access": false,
    "app_access": true
}')

SALES_POLICY_ID=$(echo $SALES_POLICY_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✅ Sales Operations Policy created: $SALES_POLICY_ID${NC}"

# 2.2 User Profile Policy
echo "Creating User Profile Policy..."
USER_POLICY_RESPONSE=$(make_api_call "POST" "/policies" '{
    "name": "User Profile Access",
    "icon": "person",
    "description": "Access to user profiles and basic settings",
    "ip_access": [],
    "enforce_tfa": false,
    "admin_access": false,
    "app_access": true
}')

USER_POLICY_ID=$(echo $USER_POLICY_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✅ User Profile Policy created: $USER_POLICY_ID${NC}"

# 2.3 Department Management Policy
echo "Creating Department Management Policy..."
DEPT_POLICY_RESPONSE=$(make_api_call "POST" "/policies" '{
    "name": "Department Management",
    "icon": "domain",
    "description": "Access to departments and organizational structure",
    "ip_access": [],
    "enforce_tfa": false,
    "admin_access": false,
    "app_access": true
}')

DEPT_POLICY_ID=$(echo $DEPT_POLICY_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✅ Department Management Policy created: $DEPT_POLICY_ID${NC}"

# 2.4 Manager Operations Policy
echo "Creating Manager Operations Policy..."
MGR_POLICY_RESPONSE=$(make_api_call "POST" "/policies" '{
    "name": "Manager Operations",
    "icon": "supervisor_account",
    "description": "Enhanced access for managers including approvals",
    "ip_access": [],
    "enforce_tfa": false,
    "admin_access": false,
    "app_access": true
}')

MGR_POLICY_ID=$(echo $MGR_POLICY_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✅ Manager Operations Policy created: $MGR_POLICY_ID${NC}"

# Step 3: Create Roles
echo -e "${YELLOW}Step 3: Creating Roles...${NC}"

# 3.1 Sales Representative Role
echo "Creating Sales Representative Role..."
SALES_REP_ROLE_RESPONSE=$(make_api_call "POST" "/roles" '{
    "name": "Sales Representative",
    "icon": "person",
    "description": "Field sales representatives",
    "admin_access": false,
    "app_access": true
}')

SALES_REP_ROLE_ID=$(echo $SALES_REP_ROLE_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✅ Sales Representative Role created: $SALES_REP_ROLE_ID${NC}"

# 3.2 Sales Manager Role
echo "Creating Sales Manager Role..."
SALES_MGR_ROLE_RESPONSE=$(make_api_call "POST" "/roles" '{
    "name": "Sales Manager",
    "icon": "supervisor_account",
    "description": "Sales team management",
    "admin_access": false,
    "app_access": true
}')

SALES_MGR_ROLE_ID=$(echo $SALES_MGR_ROLE_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✅ Sales Manager Role created: $SALES_MGR_ROLE_ID${NC}"

# 3.3 Department Manager Role
echo "Creating Department Manager Role..."
DEPT_MGR_ROLE_RESPONSE=$(make_api_call "POST" "/roles" '{
    "name": "Department Manager",
    "icon": "admin_panel_settings",
    "description": "Department heads and managers",
    "admin_access": false,
    "app_access": true
}')

DEPT_MGR_ROLE_ID=$(echo $DEPT_MGR_ROLE_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✅ Department Manager Role created: $DEPT_MGR_ROLE_ID${NC}"

# Step 4: Create Test Users
echo -e "${YELLOW}Step 4: Creating Test Users...${NC}"

# 4.1 Test Sales Representative
echo "Creating Test Sales Representative..."
TEST_SALES_REP_RESPONSE=$(make_api_call "POST" "/users" '{
    "first_name": "Ahmed",
    "last_name": "Al-Rashid",
    "email": "ahmed.sales@urbanvision.com",
    "password": "test123456",
    "role": "'$SALES_REP_ROLE_ID'",
    "status": "active",
    "territory_assignment": "Dubai Commercial",
    "phone_uae": "+971-50-123-4567"
}')

echo -e "${GREEN}✅ Test Sales Representative created: ahmed.sales@urbanvision.com${NC}"

# 4.2 Test Sales Manager
echo "Creating Test Sales Manager..."
TEST_SALES_MGR_RESPONSE=$(make_api_call "POST" "/users" '{
    "first_name": "Fatima",
    "last_name": "Al-Zahra",
    "email": "fatima.manager@urbanvision.com",
    "password": "test123456",
    "role": "'$SALES_MGR_ROLE_ID'",
    "status": "active",
    "territory_assignment": "UAE National",
    "phone_uae": "+971-50-987-6543"
}')

echo -e "${GREEN}✅ Test Sales Manager created: fatima.manager@urbanvision.com${NC}"

# Step 5: Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 RBAC Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}Created Policies:${NC}"
echo "• Sales Operations Access: $SALES_POLICY_ID"
echo "• User Profile Access: $USER_POLICY_ID"
echo "• Department Management: $DEPT_POLICY_ID"
echo "• Manager Operations: $MGR_POLICY_ID"
echo ""
echo -e "${YELLOW}Created Roles:${NC}"
echo "• Sales Representative: $SALES_REP_ROLE_ID"
echo "• Sales Manager: $SALES_MGR_ROLE_ID"
echo "• Department Manager: $DEPT_MGR_ROLE_ID"
echo ""
echo -e "${YELLOW}Test Users Created:${NC}"
echo "• Sales Rep: ahmed.sales@urbanvision.com (password: test123456)"
echo "• Sales Manager: fatima.manager@urbanvision.com (password: test123456)"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Visit ${DIRECTUS_URL} and login as admin"
echo "2. Go to Settings → Access Control → Access"
echo "3. Configure permissions for each Role + Policy combination"
echo "4. Test login with the created test users"
echo ""
echo -e "${GREEN}Access the admin panel: ${DIRECTUS_URL}${NC}"

# Save configuration for reference
cat > rbac-config.txt << EOF
Urban Vision ERP - RBAC Configuration
=====================================

Policies Created:
- Sales Operations Access: $SALES_POLICY_ID
- User Profile Access: $USER_POLICY_ID
- Department Management: $DEPT_POLICY_ID
- Manager Operations: $MGR_POLICY_ID

Roles Created:
- Sales Representative: $SALES_REP_ROLE_ID
- Sales Manager: $SALES_MGR_ROLE_ID
- Department Manager: $DEPT_MGR_ROLE_ID

Test Users:
- ahmed.sales@urbanvision.com (Sales Rep)
- fatima.manager@urbanvision.com (Sales Manager)

Access Token (for reference): $ACCESS_TOKEN

Generated: $(date)
EOF

echo -e "${GREEN}✅ Configuration saved to rbac-config.txt${NC}"
