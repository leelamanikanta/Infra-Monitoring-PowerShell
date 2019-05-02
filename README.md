# Script to Monitor Disk space and Monitor SQL service on the servers

Input: Server names in csv format
Output: Alert mail

Scope:
  Script checks disk space of all the servers in the inventory if the diskspace is less than 15 % triggers an email.
  Script also checks if the SQL services in the servers and tiggers an email if SQL services are stopped(Can be customised to monitor any service in the server).
 
Further Enhancements:
  It can be extended to monitor other resources in the server like RAM,CPU utalization, Specific events in the event log.

