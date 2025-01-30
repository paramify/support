---
outline: 2
---

<!--
For each release create a new section at the top with heading including the version that clients would see in the app (i.e., 1.18.0) and release date, followed by subsections (if applicable) for:
- New Features
  New capabilities that we want clients to be able to use. Include screenshots or links to docs on how to use the new features.
- Improvements
  Any general improvements or fixes that are significant enough to make clients aware of.
- Deployments
  Updates or notes specific to self-hosted deployments. Include any new config changes, etc.
- Security
  Let clients know when security improvements are made, including severity as applicable (e.g., minor changes that are beneficial, major improvements that are recommended).

Once the release notes are approved and merged then notification should be sent to clients (TBD, via releases@paramify email list?).
-->

# Release Notes

> Notable changes and improvements to Paramify Cloud and self-hosted deployments.

<!-- >Subscribe to release notifications (TBD) -->

![paramify](/assets/hero-rocket.png)

## 1.47.0 (January 30, 2024)

### Improvements

- Alpha Evidence: Various improvements
- Alpha Evidence: DocRobot can include evidence associated with controls in ATO package
- Alpha POA&Ms: Various improvements
- Control Implementation: Text search now includes additional fields
- DocRobot: Improvements to make document creation more robust
- Issues: Improvements to make import FedRAMP POA&M document functionality more robust
- Issues: Provide ability to download filtered issues into CSV
- Project: Improvements to make import project files more robust
- SSP: Improvement to include SSP revision number in file name
- User profile: Allow Admins to change user email addresses

### Fixes

- Alpha Evidence: Various bug fixes
- Alpha POA&Ms: Various bug fixes
- CIS-CRM: Fixed issue where control enhancement was not always appearing
- Generate Suggested Risk Solutions: Various fixes 
- Risk Solutions: Fixed navigation issue
- Smart Text Tool Tip: Fixed issue where captions were incorrectly marked as “not set”
- User Summary: Fixed issue with manual and auto mode

### Security

This release includes security-related dependency updates. Updating is recommended for all users.

## 1.46.0 (January 17, 2024)

### Improvements

- Alpha evidence and POA&M management functionality for limited audience
- Control Implementation: Streamlined ability to bulk change target date
- Stacks: Migrated Teams data to Stacks
- StateRAMP: Updated SSP formatting

### Fixes

- Flags: Fixed various issues with flag management
- Merge Request and Pull Requests
- User Summary: Fixed issue with manual and auto mode

## 1.45.0 (January 8, 2024)

### Improvements

- Admin: Allow workspace admin to configure the allowed login methods for workspace(s)
- Admin: Expanded current Okta-specific SAML implementation to support more generic SAML providers (e.g. Keycloack)
- Control Implementation: Added “Find and Replace” feature for text content and mentions in Custom Responses
- Documents: Improved styling in Li-SaaS CIS document
- Documents: Improved Control Origination Selection, preventing redundant selections if origination is Service Provider Hybrid
- Elements: Added bulk element delete which warns when elements that are mentioned will be deleted
- General: The “Library” in now called “Resources”
- Parameters: The Advanced Parameter Settings modal now navigates through parameter by parameter rather than skipping to the next control

### Fixes
- Control Implementation: Fixed issue where Custom Response to Risk Solution would cause Title to be grey
- Control Implementation: Fixed issue where controls required in DoD ILs were not correctly marked as 'required' in the UI, also added some missing recommended parameters to DoD requirements
- Documents: Fixed bug where document revision number wasn’t updating correctly
- Documents: Fixed bug where leveraged authorizations on Custom Responses not explicitly selected in manual mode; Leveraged Authorizations section of Project Overview were not shown in SSP
- Documents: Fixed bug where SSP would not generate if PM controls were selected in project.
- Documents: Added missing FedRAMP Package ID and authorization type to FedRAMP Rev 5 SSP Leveraged Authorization table
- Documents: Addressed issue with failure to generate SSPs in self-hosted, air-gapped environments
- Elements: Fixed bulk action for changing target date on eligible components and locations
- Projects: Fixed bug where importing of some FedRAMP Rev 4 SSPs would fail, improve the amount of data added to project from imported file
- Projects: Fixed bug where migrating older FedRAMP Rev 4 projects to Rev 5 would cause crash, and some attachments were not generated correctly
- Reviewers: Fixed an issue preventing users from being invited to the workspace through email
- Risk Solutions: “Set Remarks” bulk action no longer breaks existing mentions on the affected Risk Solutions

### Security

This release includes security-related dependency updates. Updating is recommended for all users.

## 1.44.0 (December 12, 2024)

### Improvements

- Control Implementation: Added filter flags for identifying problems
- Control Implementation: Added option to download control implementations (CSV) for selected controls
- Document Robot: Added OSCAL file to CMMC export
- Elements: Added management details side panel displays implementation and assurance details
- Elements: Added additional bulk change options to the following fields: target date and remarks
- Import: Enhanced robustness allows successful file imports even when some table columns are missing
- Issues: Enhanced text search of issues
- Issues: Add additional filters, including: time frame, assigned, level, and others
- Login: SAML now supports GCM
- Project Dashboard: Return project progress widget to original liquid design
- Projects: Move User Summary details from attachments to project overview section tab for FedRAMP Rev5
- Projects: Added check to prevent deletion of projects with DoD dependencies
- Risk Solutions: Added management details side panel displays implementation and assurance details
- Risk Solutions: Added additional filter flags for identifying problems
- Solution Responses: Enabled copying rich text for easy use in questionnaires and similar tasks
- SSP Import: Better handling for AC-1 subparts

### Fixes

- Control Implementation: Fixed review status filter
- Document Robot: Fixed order of CMMC requirements in the SSP document.
- Documents: Fixed some rich text lists having the wrong format.
- Documents: Fixed Leveraged Authorizations not displaying POC info in FedRAMP Rev4.
- Deployments: Ensure air-gapped deployments use static element data
- Elements: Fixed import activity missing fields.
- Issues: Fixed bug where imports crashed due to invalid requirements
- Mentions: Cleanup up orphaned mentions causing problems.
- Projects: Updated the export file version.
- Projects: Handle special characters in project name when exporting projects.
- Risk Solutions: Fix broken mentions from duplicated solutions.
- Risk Solutions: Fixes bug where resolved comments were unable to be reopened.
- Risk Solutions: Remove “Shared” origination from bulk actions

### Security

This release includes security-related dependency updates. Updating is recommended for all users.

## 1.43.0 (November 25, 2024)

### Improvements

- Attachments: Custom attachments can now be reordered
- Control Implementation: Issues can now be created directly from the control page
- Control Implementation: Issues associated with controls can now be accessed from the control page
- Control Implementation: Making changes on a control requirement resets the “reviewed” status
- Comments: Filter various lists by whether comments are active or resolved
- Crosswalk: Added beta functionality to generate crosswalk
- Elements: Performance improvements
- Elements: Changing an element name now warns of potential side effects
- Issues: Revamped the issue creation flow
- Issues: Uploading POA&M spreadsheet will automatically apply correct control parts to issues
- Issues: The issue API now supports milestone CRUD functionality
- Issues: Included link to CVSS calculator based upon associated CVE ID
- Issues: Support for commenting, reviewing, and assigning
- Project Overview: Custom sections can now be reordered
- Risk Solution: Responsible roles can now be assigned through a bulk action
- Documents: Improves readability of applicable services by listing them below the responses.

### Fixes

- Editor: The editor toolbar correctly locks to the top of the page when scrolling on multi-page content
- Parameters: Multiple choice parameters now correctly display after making a selection
- Risk Solutions: Mentions in lists will now parse correctly
- Documents: Fixed leveraged services table to only show IaaS, PaaS, and SaaS services as per FedRAMP guidelines.
- Control Implementation: Fixed issue where updating Control Requirements with active search filter caused page to crash and not update data if the requirement no longer matched the filter criteria.

### Security

- This release includes security-related dependency updates. Updating is recommended for all users.



## 1.42.0 (November 7, 2024)

### Improvements

- Bulk Action: Added confirmation when bulk actions were completed successfully
- Data Flows: Allow more flexibility for source and destination components
- Documents: Evidence files are now included with POA&M package
- Issues: Added ability with Document Robot to generate a folder containing relevant evidence when producing POA&M documentation 
- Navigation: Various improvements to reduce number of clicks throughout the app
- Risk Solutions: Added the ability to bulk change team, origination, main component, implementation, target date, remarks

### Fixes

- Elements: Various bug fixes
- Documents: CMMC controls are now ordered correctly in the SSP
- Documents: CMMC projects now export OSCAL files as expected
- Documents: Fixed Appendix Q not always printing component names
- Documents: Improved Appendix Q table formatting
- Projects: Fixed CMMC dashboard reporting incorrect SPRS score in edge cases
- Risk Solutions: Fixed dashboard review percentage calculation when project contains custom responses
- Rich Text: Fixed issue where invalid content could be copied and pasted between editors


## 1.41.0 (October 23, 2024)

### Improvements

- Controls: Implemented page load performance improvements
- Controls: Added flag to identify controls with invalid mentions 
- Controls: Added ‘Apply suggested Risk Solution to selected controls’ bulk action
- Data Flows: Added option for data flow import and export
- Documents: Add auto increment of version number to document generation through Document Robot
- Elements: Added the ability to bulk change team, responsible role, status, vendor, and leveraged systems
- Elements: Added ability to filter by additional criteria
- POAMs: Added notice to user when closing issue with open milestones
- Projects: Continued improvements for CCF projects including custom control language
- Risk Solutions: Improved speed of Risk Solution import
- Risk Solutions: Added the ability to bulk change team, origination, main component, implementation, target date, and remarks

### Fixes

- Attachments: Fixed duplicate attachments on StateRAMP projects
- Controls: Fixed capitalization of elements and mentions
- Document Robot: Fixed issue with FedRAMP Li-SaaS Rev 5 producing incomplete templates
- Data Flows: Removed redundant fields
- Elements: Fixed IP and DNS fields appearing as drop down list when adding an inventory item
- POAMs: Improved various issues when importing POAMs
- POAMs: Fixed various formatting issues
- Risk Solutions: Removed unnecessary project-mappings columns
- Risk Solutions: Fixed prompt that suggested creating a duplicate main component
- Risk Solutions: Fixed filter counts to always show the count and total 

### Deployment

- Reduced container start-up time

### Security

This release includes security-related dependency updates. Updating is recommended.

## 1.40.0 (October 7, 2024)

### Improvements

- Controls: Added additional requirements and guidance information to control descriptions
- Projects: Continued improvements for CCF support for SOC 2
- Projects: Added early support for FISMA catalogs (Beta)
- Risk Solution: Added ability to apply suggested mappings to a project in the mapping view
- Control Implementation: Improved warnings on invalid data
- Elements: Added multi-select to list view

### Fixes

- Mentions: Fixed issue causing mentions to be broken until browser refresh
- Documents: Fixed nested bullets formatting issues
- Documents: Fixed “Used by” column in Ports, Protocols, and Services table showing unexpected output
- Documents: Fixed CIS to list by control requirement instead of by control
- Documents: Fixed “Organization Name” mentions not being display properly
- Documents: Fixed some attachments not being properly listed
- Workspace Settings: Okta tooltip now points to up to date documentation in http://docs.paramify.com 
- Project Overview: Corrected issue causing user summary to log too many interactions
- Project Overview: System Interconnection names no longer display the 'invalid type' tooltip on hover
- Project Overview: Fixed issue preventing access of “System Ports, Protocols & Services” page
- List Views: Fixed issue with next and back navigation buttons not always respecting filters on detail pages
- Elements: Fixed permissions issues for deleting elements
- SSO: Fixed Okta users not getting redirected when already logged in
- Risk Solutions: Fixed issue with showing incorrect review status
- Imports: Improved warnings when handling review data
- Imports: Fixed review content not being included in element imports and exports
- Imports: Improve import handling for manual updated element records

### Deployment

Added configuration option to enable services to connect to FIPS-compliant endpoints in AWS.

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.39.0 (September 10, 2024)

### Improvements

- Controls Implementation: Added view toggle and list view with selectable columns
- Controls Implementation: Updated design of detail view including Reviewer details
- Custom Responses: AI-suggested Risk Solutions based on Custom Responses (alpha)
- Documents: Initial generation of FedRAMP Appendix Q from related data flows
- Elements: New list view with initial filters and selectable columns
- Elements: Updated design of detail view including Data Flows and Reviewer details
- Mentions: Added ability to click on a Mention and unlink it (back to plain text)
- Projects: Include Front Matter in SSP and Appendix A imports (beta)
- Projects: Early support for Adobe Common Controls Framework (CCF) projects for SOC2
- Projects: Updated StateRAMP to support Rev 5 controls
- Risk Solutions: Added option to copy project mappings when duplicating a Risk Solution
- Fixed Controls Implementation to show tooltip with Reviewer of linked Risk Solutions
- Fixed Controls Selection when viewing Controls to properly show System Name
- Fixed Custom Responses error when setting Originations and Responsible Roles
- Fixed Custom Responses export of Control Implementations to include missing header
- Fixed Custom Responses so "Add Mentions" can fix invalid mentions of matching names
- Fixed Custom Responses to allow setting family when saving as a Risk Solution
- Fixed Custom Responses with global option to toggle titles in Project Settings
- Fixed Documents for Appendix A so Origination Status order matches FedRAMP template
- Fixed Documents to include headings and table of contents for custom sections
- Fixed Documents to properly show Organization when mentioned in system description
- Fixed Elements detail view to properly navigate when the list is filtered
- Fixed Exports to be properly restricted based on Project licensing
- Fixed Images support in Azure Government related to bug in Azure client
- Fixed Issues to avoid potential error when reopening an issue with remarks
- Fixed Key Contacts problem when trying to create entries directly in selector
- Fixed Login to ignore case when matching user email addresses
- Fixed Login to use UPN from Azure AD with Microsoft Login instead of email address
- Fixed Projects dashboard progress to ignore Review Status for Custom Responses
- Fixed Projects error viewing System Ports, Protocols & Services in Project Overview
- Fixed Projects changes to user counts from resetting selections in User Summary
- Fixed Projects so User Summary can properly show completed in Project Overview
- Fixed Projects to show proper base project Impact Level on DoD projects
- Fixed Risk Solutions import/export to included assigned Reviewer and Review Status
- Fixed Risk Solutions list view with selectable columns and sort options
- Fixed Risk Solutions to flag mismatched Teams compared to the Main Component
- Fixed Risk Solutions to honor filters when using multi-select
- Fixed UI to prevent potential error when selected User was removed from Workspace

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.38.0 (August 21, 2024)

### Improvements

- Controls Implementation: Added option to download controls matrix as CSV
- Custom Responses: Option to "Create Elements" in text and convert to Mentions (alpha)
- Risk Solutions: Added filter option for Assigned Reviewer
- Risk Solutions: Added option to show full control text when adjusting mappings
- Risk Solutions: Multi-select with bulk actions to assign reviewers or mark reviewed
- Risk Solutions: New ability to assign a reviewer and add resolvable comments
- Fixed Documents to allow Regenerate option if there was an error during generation
- Fixed Elements export then import from having an error under some conditions
- Fixed Issues to avoid rare crash when editing Remediation text or closing an Issue
- Fixed Parameters crash switching projects after setting "Show DoD Settings" flag
- Fixed Projects migrate to FedRAMP Rev 5 to include responsible role of Custom Responses
- Fixed Projects to show correct status for Project Overview sections with diagrams
- Fixed Risk Solutions export from having Mentions showing as "undefined"
- Fixed Risk Solutions to prevent an error due to too long of a title

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.37.0 (August 8, 2024)

### Improvements

- Risk Solutions: Added ability to assign Reviewer and "changes requested" status
- Teams: Allow assigning Teams to Elements and Risk Solutions to simplify grouping
- Workspaces: Added option to limit what Collaborators can review
- Fixed Documents for FedRAMP Appendix A to drop section in table number caption
- Fixed Documents generation to give warning if images are missing
- Fixed Documents to include revision number in package filename
- Fixed Documents to more consistently indent body text
- Fixed Elements from showing a 400 error after editing certain fields
- Fixed Issues import of invalid files from potentially crashing application
- Fixed Risk Solutions dashboard links to properly apply filters
- Fixed Risk Solutions flag for "potential duplicate" to include manually copied
- Fixed Risk Solutions to filter for specific attributes not being set
- Fixed Risk Solutions to show flag when imported with invalid Mentions

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.36.0 (July 26, 2024)

### Improvements

- Attachments: Show blue robot icon on each attachment with autogeneration enabled
- Documents: Added option to regenerate the latest revision
- Documents: Include custom sections from Project Overview in generated SSP
- Elements: Added "Create New" button on detail view for quicker additions
- Elements: Added ability to convert an Element to a different type
- Elements: Added warning with number of mentions when deleting Elements
- Elements: Improved icons to better differentiate between Roles
- Issues: Added option to replace existing Issues on import
- Projects: Added option to retain Custom Responses when deselecting controls
- Projects: Initial support for importing SSP (or Appendix A) for FedRAMP
- Projects: Support for level-specific limits when setting security impact
- Risk Solutions: Added ability to multi-select profiles to filter on summary page
- Risk Solutions: Added control family, compliance profile, and requirement to filters
- Risk Solutions: Added flag for Main Component implementation mismatch
- Risk Solutions: Added previous/next navigation buttons on detail view
- Risk Solutions: Moved mappings into right drawer for easier comparison
- UI: Added visible "Alpha" and "Beta" flags on specific features
- Fixed Attachments to more clearly indicate which can be automaticially generated
- Fixed Attachments to properly save and view Comments in Activity
- Fixed Documents revision Activity to indicate SSP vs POAM changes
- Fixed Elements import from causing an error with certain existing data
- Fixed Glossary and Acronyms from being visibile in other workspaces
- Fixed Glossary and Acronyms to ignore capitalization when sorting
- Fixed Imports of too large files not giving a useful warning message
- Fixed Issues from clearing origination when editing options on right sidebar
- Fixed Issues import warnings to distinguish between failed rows and missing fields
- Fixed Issues to show consistent dates regardless of timezone
- Fixed Projects migration from FedRAMP Rev4 to keep relevant Custom Responses
- Fixed Projects to only allow creating DOD addendum on FedRAMP base projects
- Fixed Risk Solutions view to properly filter by Responsible Role

### Deployments

- Initial support for deployment to Google Cloud
- Enable deployment using new version of Embedded Cluster (beta)

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.35.0 (July 9, 2024)

### Improvements

- Documents: Added option to include eMASS spreadsheet when generating documents
- Issues: Added license option to grant a list of users access to Issues alpha
- Workspaces: Ability to specify multiple Admins to be provisioned during deployment
- Workspaces: Support for provisioning multiple workspaces based on license
- Fixed Custom Responses from being removed when deleting all Risk Solutions
- Fixed Documents for FedRAMP Rev4 to include custom Acronyms and Glossary
- Fixed Documents for FedRAMP Rev5 to always include Appendix L
- Fixed Elements to disallow setting an empty name
- Fixed Images content security to support old AWS S3 bucket naming (with dots)
- Fixed Images failing to load in Firefox due to extra slash in Azure endpoint
- Fixed Risk Solutions not always saving Remarks for implementation status
- Fixed Risk Solutions reviewed status being reset when no changes were made

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.34.0 (June 28, 2024)

### Improvements

- Attachments: Added option to selectively enable or disable auto-generation
- Attachments: Enabled managing User Summary details for FedRAMP Rev5 in Attachment options
- Documents: Added ability to export revision history
- Issues: Added support for importing POAMs from FedRAMP template xlsx (in addition to csv)
- Risk Solutions: Flags errors and warnings on potential problems that need attention
- Risk Solutions: Improved usability of view for managing suggested mappings
- Risk Solutions: Initial Crosswalk summary to show applicability to other profiles
- Fixed Editors to limit height and scroll content for some use cases
- Fixed missing StateRAMP template for PIA attachment
- Fixed Projects to include missing Activity for changes to Project Settings
- Fixed Risk Solutions being detached from library not properly created as Custom Response
- Fixed Risk Solutions review status from being reset by just clicking in and out of editor


## 1.33.0 (June 18, 2024)

### Improvements

- Documents: Adjust required Attachments based on project security impact level
- Documents: Initial support for Crosswalk document of Risk Solutions across catalogs
- Workspaces: Added ability for Admin to rename their Workspaces
- Workspaces: Initial support for provisioning multiple Workspaces
- Fixed Activity logs to reduce reporting of empty changes
- Fixed Documents for POAM to always show Status Date
- Fixed Elements to prevent error when adding Revisions
- Fixed Images using Azure Blob storage that won't load due to security policy
- Fixed Imports of Revisions to support external URL links
- Fixed Issues detail page to load less data for faster response
- Fixed Projects to prevent potential error when viewing Controls Selection
- Fixed Risk Solutions by streamlining project and suggested mappings experience
- Fixed Risk Solutions to only show Subfamily when a Family is specified

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.32.0 (June 10, 2024)

### Improvements

- Documents: Added custom Appendix A attachment for FedRAMP LI-SaaS projects
- Issues: Added icon for selected issue type next to ID in list view
- Issues: Added next/previous navigation buttons to detail page
- Issues: Added sortable Due Date field to list view
- Issues: Added type selection dialog when creating new Issues
- Issues: Calculate initial Due Date as standard SLA from observation date
- Issues: Support importing Point of Contact from POAM template
- Risk Solutions: Expanded text search to also match main components and mentions
- Fixed Documents to add statement of user counts to CMMC
- Fixed Documents to export POAM template with proper filename
- Fixed Documents to include images in descriptions for CMMC
- Fixed Documents to include plugin ID in generated POAM template
- Fixed Documents to show system unique identifier for CMMC
- Fixed Glossary and Acronyms to warn when trying to add a blank entry
- Fixed Imports of Elements to warn when attempting to link invalid types to Data
- Fixed Imports of Issues to better handle missing columns and truncated rows
- Fixed Imports of Issues to give warnings on invalid or duplicate origins
- Fixed Imports of Projects to warn when linking non-unique Risk Solutions
- Fixed Issues to not include empty party references in OSCAL
- Fixed Issues to properly search by name when selecting origins
- Fixed Projects being deleted from returning an error in certain cases
- Fixed Projects to include GR controls in DOD Rev 5
- Fixed Risk Solutions to not show "null" in content for invalid smart text

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.31.0 (May 23, 2024)

### Improvements

- Elements: Added initial global import and export for Inventory
- Issues: Added ability to filter by Deviation status
- Issues: Added ability to specify impacted assets
- Issues: Added support for multiple originations
- Issues: Improved Links editing and shows favicon for known domains
- Issues: Link valid CVE IDs to NIST summary page
- Fixed Collections to also include Software as a filter option
- Fixed Documents for POAM to include CSP, System Name, and other metadata
- Fixed Documents for POAM to include more fields for Deviations
- Fixed Documents to correctly identify Inherited originations
- Fixed Documents to improve Inventory workbook for FedRAMP Rev 5
- Fixed Documents to show open and closed POAMs on proper sheets
- Fixed Imports of Elements to not warn when missing unnecessary fields
- Fixed Issues to report "changes saved" on updates
- Fixed Projects from reporting a 500 error after deletion
- Fixed Projects security impact level from extending off small windows
- Fixed Projects to delete diagram images on project deletion
- Fixed Projects to import proper catalog for StateRAMP
- Fixed Projects to include Alternative Implementation in CMMC SPRS score
- Fixed UI dropdowns to select when clicking anywhere in row
- Fixed UI to include page titles on all pages

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.30.0 (May 13, 2024)

### Improvements

- Controls Implementation: Adds full text search to Link Risk Solutions view
- Documents: Added KEV (Known Exploited Vulnerabilites) to generated POAM document
- Documents: Updated POAM generation to include more details of Deviations
- Issues: Added ability to show/hide Due Date column in list view
- Issues: Added more data including Point of Contact, Impacted Requirements, and Links
- Issues: Added option for Admins to delete all Issues (with warning)
- Issues: Added Status Date to detail view and generated POAM document
- Issues: Improved overall layout of detail view
- Issues: Included Activity log of changes to list and detail views
- Fixed Documents to properly set Inherited originations checkbox
- Fixed Issues to show consistent UTC-based milestone dates
- Fixed Projects to preview result when changing impact level to Default


## 1.29.0 (May 7, 2024)

### Improvements

- Documents: Initial generation of FedRAMP POAMs documents from Issues
- Issues: Added ability to show/hide CVE in list view
- Issues: Added limited rich text descriptions where supported
- Issues: Allows manually setting or autogenerating unique POAM ID
- Issues: Made POAM ID and CVE visible and searchable in list view
- Issues: Supports importing from POAM template CSV
- Fixed Attachments download link for FedRAMP Appendix O template
- Fixed Attachments for TX-RAMP workbook to include parameters
- Fixed Attachments for TX-RAMP to better name workbook file
- Fixed Attachments to include both Acronyms and Glossary terms
- Fixed Attachments to properly identify Shared and Hybrid originations
- Fixed CMMC projects by removing unnecessary Data types selection
- Fixed Element imports to not warn about missing FedRAMP systems
- Fixed Images being deleted to also be removed from storage
- Fixed Issue detail to always show adjusted risk level
- Fixed OSCAL export compliance against NIST schema
- Fixed OSCAL export from mishandling non-string parameters
- Fixed Risk Solutions filters to sort Responsible role options
- Fixed Documents to prevent overflow of table cells
- Fixed Import dialogs to not remember previous filenames

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.28.0 (April 19, 2024)

### Improvements

- Issues: Improved detail view of Observations, Deviations, and Recommendations
- Issues: Initial version of OSCAL generation of POAMs
- Issues: Added initial ability to attach Evidence
- Issues: Added support for deleting Issues
- Projects: Added ability to create base project when creating new DoD project
- Projects: SPRS score included on CMMC dashboard
- Fixed Attachments to highlight and show newly created Custom Attachment
- Fixed Attachments for Li-SaaS projects to reduce list of required
- Fixed Attachments to prevent changing filename extension of generated files
- Fixed Documents to correct CSP inheritance in CRM and leverage Risk Solutions to explain customer responsibilities
- Fixed Imports to improve warning messages and identify missing fields in source file
- Fixed Key Contacts by removing FedRAMP contacts from CMMC projects
- Fixed Mentions to allow dragging the scrollbar when selecting Elements
- Fixed User management to better support multiple workspaces
- Fixed Warnings in browser on several pages related to library deprecations and improvements

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.27.0 (March 27, 2024)

### Improvements

- Attachments: Icons now indicate which are automatically generated or can download templates
- Documents: Added User Summary as Appendix S to FedRAMP Rev 5
- Documents: Policies and Procedures attachment added to CMMC (pre-beta)
- Implementations/Risk Solutions: Remarks now support mentions and rich text formatting
- Implementations/Risk Solutions: Tables in rich text can now set a header row
- Issues: Added summary dashboard, filters, sorting, and detail views for POAMs (alpha)
- Projects: Revision History can now be uploaded
- Fixed Advanced Parameters using "Show DoD" flag to be more persistent
- Fixed Attachments to show "Not Applicable" status as complete only with remarks
- Fixed Attachments view to properly refresh remarks when navigating
- Fixed Collections import to properly link applicable products
- Fixed Dashboard charts to include User/Role filters when clicking to detail view
- Fixed Implementations to remove unused parameters
- Fixed Imports to prevent submitting without selected file and improve various warnings
- Fixed Imports with images in rich text content with some storage providers
- Fixed Key Contacts to select the Person/Org created with "+ Create" button
- Fixed Paramify Cloud application "502" errors caused by large headers
- Fixed Project Dashboard "Select Control Set" link when no controls are selected
- Fixed Revision History to better sort version numbers
- Fixed Risk Solutions and custom responses mishandling images in text in some cases
- Fixed Risk Solutions to prevent deleting narrative when removing extra responsible role

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.26.0 (March 7, 2024)

### Improvements

- Implementations/Risk Solutions: Added support for images in rich text fields
- Documents: Initial CMMC document generation completed (pre-beta)
- Projects: Improved progress bars to animate progress and reduce shifting during load
- Projects: Adjusted dashboard progress to more heavily weight by count of controls
- Issues: Initial structure for POAMs support (alpha)
- Fixed Custom Response review status to be saved in project export
- Fixed Risk Solutions view to avoid shifting during page load
- Fixed Key Contacts to fit odd-sized images properly into avatar
- Fixed Project side navigation to properly highlight active Controls section


## 1.25.0 (March 1, 2024)

### Improvements

- Key Contacts: Made view more compact, including proper party icon and image, if set
- Controls Implementation: Show family/subfamily and sort by name in Link Risk Solutions view
- Elements: Always sort view by name
- UI: More consistent Previous/Next buttons and tooltips
- Fixed Key Contacts to always default by project type


## 1.24.0 (February 23, 2024)

### Improvements

- Projects: Initial NIST 800-171/172 catalogs and foundation for CMMC (coming soon)
- Advanced Parameters: Added "fast forward" navigation buttons to skip to previous/next incomplete
- Advanced Parameters: Shows current, total, and incomplete counts
- Project Dashboard: No longer shows sections which have no data
- Key Contacts: Removed unnecessary entries for FedRAMP projects
- Fixed Project Dashboard to report proper count of Custom Responses, if any
- Fixed Advanced Parameters UI bug that could cause the window to not open or to close unexpectedly
- Fixed Elements minor UI issue when navigating after adding an image

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.23.0 (February 16, 2024)

### Improvements

- Show Element type icon and tooltip in list when selecting mentions
- Use substring search on short and long names for mentions
- Allow merging cells (horizontally) in tables within text
- Re-add Advanced Parameters and Project Settings to Actions menu on Control Implementations
- Quick "view" link to see control text when adjusting mappings on Risk Solutions
- Fixed error when clicking on certain parts of the Risk Solutions chart to see filtered views
- Added new "demo mode" to allow limited functionality in specified workspaces
- Rename attachments to new standard when migrating from FedRAMP Rev4 to Rev5
- Prevent deleting locked Organization object from workspace
- No longer generates empty Policies and Procedures doc when no controls are selected
- Corrected rare OSCAL generation error due to broken mentions
- Fixed error when navigating between Advanced Parameter Settings
- Updated certain controls to properly show as "withdrawn"

### Deployments

- Now supports Azure Blob storage in Azure Government (see [new config](https://github.com/paramify/support/blob/main/azure/values-azure.yaml.example#L40-L48))
- Fixed use of persistent volume in embedded DB (may require backup/restore of DB)

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.22.0 (February 6, 2024)

### Improvements

- Optimized filters on Control Implementations to improve overall performance
- Able to filter Control Implementations by unassigned, leveraged system, review status, and response type
- Clicking Project dashboard donut chart now links to filtered view of relevant Control Implementations
- Fix some mentions becoming invalid during Risk Solution imports
- Fixed searching when selecting Main Component in Risk Solutions
- Ability to filter Risk Solutions by unassigned
- Added option to delete all Risk Solutions
- Fixed saving an empty Custom Response as a Risk Solution
- Added link from Project dashboard to see Custom Responses that are not reviewed
- Clarified difference between Users (accounts) and People (elements)
- Added reminder that MS Word is recommended for proper document viewing
- Fixed ordering in Project Overview when adding custom sections
- New option to easily deselect all Control Selections
- Prevent deleting the project-associated Plan element
- Updated Activity to always show latest User name
- Minor fixes to control requirements for FedRAMP Li-SaaS
- Added missing DoD Rev5 parameters

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.21.0 (January 19, 2024)

### New Features

#### Collaborators Approval Workflow

Collaborators have an optional new worklow to support approving Risk Solutions assigned to their Role. They can flag their Risk Solutions as "Approved" or "Change Requested" to assist Editors and Admins in their review process. If the Collaborator approves a Risk Solution the overall status will show as "Ready for Review", at which point an Editor or Admin can mark it reviewed. Note that this "Approval by Responsible Role" option will only be available when there is a Collaborator that is assigned a Role matching the Risk Solution.

![collaborator-approve](/assets/1.21-collaborator-approve.png)

Alternatively, if the Collaborator is unsatisfied with their Risk Solution and can't make the desired change (such as to Implementation Status or Responsible Owner) they could indicate "Change Requested" which will bubble up to those responsible for overall review. The Editor or Admin could then communicate with the Collaborator to address the feedback. Once satisfied they would click to "Resolve Change Request" and reset the Role approval status, after which they could wait for the Collaborator to approve or just mark it reviewed.

![collaborator-changes](/assets/1.21-collaborator-changes.png)

This Collaborator workflow is completely optional, and it is not required for Admins and Editors as they review Risk Solutions. It's intended to enable them to delegate part of the review process to Collaborators as subject matter experts to (optionally) edit and approve based on their responsible Role. See the related Collaborator Access options in Workspace Settings.

### Improvements

- Fixed performance issue waiting for document generation
- Options in Workspace Settings to restrict Collaborators to only see Elements and/or Risk Solutions assigned to their role
- When applying suggested Risk Solutions the default option is now to skip Control Implementations with existing responses
- Able to filter for linked Risk Solutions in Control Implementations
- Now able to review Custom Responses (similar to Risk Solutions)
- Added loading indicator while importing files
- Added ability to delete your own comments (or Admin can delete any)
- Improved Risk Solutions view for lower resolution screens
- Minor improvements to FedRAMP and DoD documents
- Better naming convention for document attachments

### Deployments

Added option for automated backups of embedded database.


## 1.20.0 (January 11, 2024)

### Improvements

- Search filters persist on Elements, Control Implementations, and Risk Solutions
- Limit next/previous navigation of Elements and Control Implementations within search results
- Click diagram thumbnails to show full-sized image
- Allow multiple Leveraged Authorizations in Custom Responses
- Ability to filter search of Control Implementations by Leveraged System
- Option to show only suggested Risk Solutions when manually linking to Control Implementation
- Option to hide titles on Custom Responses now under Project Settings
- More detailed error notifications on Element and Risk Solution imports
- Document generation errors now show as tooltip to facilitate troubleshooting
- Option to expand/collapse all response details in Control Implementation
- Searching Acronyms and Glossary now include definitions
- Various formatting improvements on FedRAMP Rev5 and DoD SSP documents

### Security

This release includes security-related dependency updates. Updating is recommended.


## 1.19.0 (December 21, 2023)

### Improvements

- Add section in Project Overview to allow automatic or manual listing of Leveraged Authorizations
- Deleting all Elements will replace mentions with text name in Risk Solutions and Custom Responses
- Option to delete all existing Custom Responses when importing Solution Responses in Project Settings
- Retain references to applied Risk Solutions in Project export
- Fix failure to import Parameters under certain conditions
- Improve sorting list of Project names and when selecting items from dropdowns

### Deployments

Allow connecting to SMTP servers with self-signed certificates by default.


## 1.18.1 (December 14, 2023)

### Deployments

Minor improvement to include some missing app logs in support bundles.


## 1.18.0 (December 7, 2023)

### Improvements

- Floating formatting toolbar will stay visible when editing long text in Risk Solutions and Custom Responses
- Able to filter Control Implementation by Origination and Status
- Notifications and warning messages will stay until closed
- Able to globally toggle titles on Responses in Project Settings
- Ensure high resolution images in documents

### Deployments

Allow sending SMTP mails without authentication by leaving either SMTP user or password blank.

### Security

This release includes security-related dependency updates. Updating is recommended.
