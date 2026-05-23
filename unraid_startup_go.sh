#!/bin/bash
# Policy-Based Routing for Symmetric NFS Traffic (Streaming Only)

# --- USER CONFIGURATION ---
STREAMING_IP="192.168.1.101"
STREAMING_NIC="eth1"        # adapter to dedicate to streaming traffic. no gateway, static IP
SUBNET="192.168.1.0/24"
TABLE_NAME="nfs_stream"
TABLE_ID=101
# --------------------------

# 1. Define the New Routing Table
if ! grep -q "$TABLE_ID $TABLE_NAME" /etc/iproute2/rt_tables; then
    echo "$TABLE_ID $TABLE_NAME" >> /etc/iproute2/rt_tables
fi

# 2. POPULATE THE NEW ROUTING TABLE
# Delete the existing route first, if it exists, to prevent duplicate routes
# We use 'ip route del' instead of 'ip route flush' to avoid the error.
ip route del $SUBNET dev $STREAMING_NIC table $TABLE_NAME 2>/dev/null

# Add the local subnet route. This is the only path in this table.
# It forces local replies to use the streaming NIC.
ip route add $SUBNET dev $STREAMING_NIC table $TABLE_NAME

# 3. CREATE THE POLICY RULE
# Delete the rule first, if it exists, to prevent duplicates
ip rule del from $STREAMING_IP table $TABLE_NAME 2>/dev/null

# Add the policy rule.
ip rule add from $STREAMING_IP table $TABLE_NAME

# To test outside the startup script
# Run everything above on the command-line (without the last line)
# To verify:
# ip route show table nfs_stream (Should only show your local subnet route).
# ip rule show (Should list the rule from <your .101 IP> lookup nfs_stream).
# Start streaming from the Shield connecting to the .101 IP and observe your NAS traffic 
# to confirm the outgoing data is now strictly on the $\mathbf{.101}$ adapter.

# IMPORTANT: Keep the Unraid start command at the end
/usr/local/sbin/emhttp 