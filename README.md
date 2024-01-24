# Maps Integration Plugin

This plugin adds Maps Integration to Marval to add the ability to display tickets on a screen based on criteria.

## Compatible Versions

| Plugin  | MSM            |
|---------|----------------|
| 0.5.x   | 14.x+          |

## Installation

Once the plugin has been installed you may need to enter the database connection details. These connection details can be obtained from the server, however under some circumstances, this may not work.
You will need to complete the folowing attributes which get passed to an internal database connection string.

+ *DBConnectionString* : The connection string, ie (without the quotes) "Data Source=dbhost;Initial Catalog=dataabasename;Integrated Security=False;User ID=dbusername;Password=userpassword"
+ *IncludeAssignmentGroups* : A list of Assignment Group to Include requests from.
+ *ExcludeDescriptionMatch* : A comma separated list of Descriptions to exclude.
+ *IncludeOnlyRequestTypes* : A comma separated list of Request Types to include (ie. INC,SRV).

The connection string exists in the file connectionStrings.config in your Marval directory.
If your Marval directory is C:\Program Files\Marval Software\MSM\ the the file will be C:\Program Files\Marval Software\MSM\connectionStrings.config

The other thing required from this plugin are two attributes, called Latitude and Longitude, which exist on the customer contact record (not the person contact record). These are used to determine the location of the request and pass this onto the google maps api.

Including Assignment Groups
The parameter IncludeAssignmentGroups can be used to filter only on those specific Assignee Primary Groups. If included, this will include only those comma separated assignment groups. For instance, if IncludeAssignmentGroups contained (without the quotes) "Service Desk,Desktop Support" then only tickets from those two assignees will be included in the results.

Include Only Request Types
The parameter IncludeOnlyRequestTypes can be used to include only the request types listed in a comma separated list. If included, this will include only those comma separated request types. This parameter uses the Acronym for the request type, as list in Maintenance | Request | Types. For instance, if IncludeOnlyRequestTypes contained (without the quotes) "INC,HR,PRB" then only tickets from three request types will be included in the results. If this parameter is blank, all request types are included.


Excluding Matching description Items
The parameter ExcludeDescriptionMatch can be used to exclude tickets where the decription contains certain case-sensitive words. For instance, if ExcludeDescriptionMatch contains (without the quotes) "temporarily,vodafone" then any tickets which contained either the word temporary or vodafone would be excluded. ExcludeDescriptionMatch is evaluated before IncludeAssignmentGroups such that any description exclusions are done prior to the assignment groups. For instance, given the above examples, if you had a ticket which was assigned to the Service Desk and contained the word vodafone, it would get excluded because it would be excluded based on description before the assignment group matching.

## Usage

The plugin provides an icon on the request screen that when clicked, will open the Google Maps page in a new window.

## Contributing

We welcome all feedback including feature requests and bug reports.
