# PEPPOL Look-Up Tool

Thanks to [Philip Helger](https://peppol.helger.com/public/menuitem-tools-rest-api) you will be able to perform accurate PEPPOL participant lookups in CLI using this bash script.

I have used a variety of tools do to participant lookups, but they either provided too much info or not enough. At least for me this bash script makes my job a lot easier.

### Install
```wget https://raw.githubusercontent.com/DokterW/plut/master/plut.sh```

```chmod +x plut.sh```

```./plut.sh```

### Usage
Search using API @ [Helger](https://peppol.helger.com/public/menuitem-tools-rest-api): ```./plut.sh search 0192:987654321``` or ```./plut.sh s 0192:987654321```

Search the ELMA directory (Norwegian participants only): ```./plut.sh elma 987654321``` or ```./plut.sh elma Company Name```

Search PEPPOL Directory: ```./plut.sh dir 0192:987654321``` or ```./plut.sh dir Company Name```

### Roadmap
* Keep tweaking the code.

### Changelog

#### 2019-09-12
* Officially released
