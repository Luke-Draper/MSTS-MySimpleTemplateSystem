# My Simple Template System

This is a side project to help me develop similar files quickly. I'd like to type as little as possible when I write a data oriented program but I often find myself implementing the same interfaces. I'm using OOP but sometimes it simply doesn't make the computer do enough for me.

I made this to solve that problem. It is a small data transfer program that takes in a JSON file and a directory holding "templates" and using jq in Bash parses it, runs the appropriate templates for each data set, gives that data set to the template for easy access, and writes the output to a designated file. You can make your JSON as long as you like, use helper functions to access the data, write bash scripting just like normal inside your templates, and even recursively call templates.

### Prerequisites

I'm using GNU bash, version 4.4.19 on Linux Ubuntu 18.04.1 bionic. This might work on windows using git bash but I'd recommend reviewing the code beforehand.

You'll also need jq. Knowing how to use it can be nice but is not required:

```Bash
sudo apt-get install jq
```

### Installing and Running

Copy the download the src folder and when you're all set up run:

```Bash
./src/MSTS.sh 'path/to/my/source.json'
```

Your source JSON file has to follow this format in order to be understood by MSTS

```JSON
{
"templateDirectory": // Path to the file folder holding the templates
"tasks": // Array holding objects representing a template operation in the form
  [
    {
    "targets": // Array holding objects representing a set of templates to run and where to put the  in the form
      [
        {
          "templates": ["template1", ...], // Array holding an ordered list of template base names (no .msts.sh extension) run to produce the output
          "destination": // The file to write the template output to
        }, ... // More templates and file destinations using these variables as needed
      ]
      "variables": // The JSON object passed into the template runs as MSTS_VARS
    } ... // More variable sets as needed
  ]
}
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
