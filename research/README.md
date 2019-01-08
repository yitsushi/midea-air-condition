My blogpost about this: https://cheppers.com/operation-ac-ctf-without-flag-part-i

Part II is in progress

###  General information about this "tutorial"

This tutorial uses techniques that are in general used for not-so-legal events. Please
do not use them against others and use only for research. I try to not teach others how to
do not-so-legal things, because they want to use their knowledge on the Dark Side. Be a Jedi,
not a Sith. Thanks.

### Hijack the communication

If you don't want to repack and sign an android package, just use the APK and certs from this repo.

#### Repack and sign the android package

First of all, you have to inject an own SSL cert into the APK. Download the android package.

Generate a new SSL cert for the HTTP connection:

```
openssl req -new -x509 -keyout test-key.pem -out test-cert.pem
openssl x509 -in test-cert.pem -out mapp.appsmb.com.crt
```

Generate a new cert for signing our modified APK:

```
keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
```

Now you have 4 files:

 - mapp.appsmb.com.crt
 - test-cert.pem
 - test-key.pem
 - my-release-key.keystore

Update the APK's ssl cert with the `mapp.appsmb.com.crt` and sign it. Simplest way:

 - Open Midnight Commander (`mc`)
 - Open the APK
 - Navigate to `assets` and copy your own `mapp.appsmb.com.crt` into this directory
 - Close Midnight Commander
 - Remove current sign from the package: `zip -d NetHomePlus.apk META-INF/\*`
 - Sign the package: `jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore my-release-key.keystore NetHomePlus.apk alias_name`

As an extra step when you are inside the APK, make a copy of the `classes.dex` file. Soon we need this one for the source code.

Now you have a signed android package with your own SSL cert inside.

#### Now you can see me

If you don't have a DNS service on your machine, just install one (I use `dnsmasq`).

Add an entry into your `dnsmasq.conf`:

```
listen-address=0.0.0.0
address=/.appsmb.com/192.168.31.145
```

where `192.168.31.145` is my own public IP, so use your own here.

Install the APK on your phone (emulator works as well, but only for basic communication, later it dies with TCP Timeout anyway).

Update your DNS server settings on your phone to use your own machine (`192.168.31.145` in my case) as DNS server.

Now the android app tries to connect to you machine instead of the real server.

Start the `proxy.rb` script (update certs if you named and placed somewhere else). Start it with `sudo`
because we have to listen on port `443`.

Now you have an HTTPS "server" that proxies all the packages to the real server with the valid SSL cert, but
between the receive and send it will print out the request/response.

Done, now you can see everything.

#### Let's read some java (meh)

Get the `classes.dex` file from the APK (check above if you don't have it yet). Download `dextool`.

Now just simply run this command:

```
d2j-dex2jar.sh classes.dex
```

Now you have a new file called `classes-dex2jar.jar`. With [jd-gui](http://jd.benow.ca/) you can open it
and see the decompiled source.

#### Extra

Start jd-gui on java8+

```
java --add-opens java.base/jdk.internal.loader=ALL-UNNAMED --add-opens jdk.zipfs/jdk.nio.zipfs=ALL-UNNAMED -jar jd-gui-1.4.0.jar
```

You can use the python decompile script. Later it was more useful than the js-gui one.

If you have any questions, feel free to ask.

---


# Useful information


### Temperature Unit
```
(byte)(
    this.sleepFunc & 0x1
  | this.tubro << 1 & 0x2
  | this.tempUnit << 2 & 0x4
  | this.catchCold << 3 & 0x8
  | this.nightLight << 4 & 0x10
  | this.peakElec << 5 & 0x20
  | this.dusFull << 6 & 0x40
  | this.cleanFanTime << 7 & 0x80)
);
```

### temperature
```
int i = (paramArrayOfByte[2] & 0xF) + 16;
this.setTemperature = i;
localDeviceStatus.setTemperature = i;
b = (byte)((paramArrayOfByte[2] & 0x10) >> 1);
this.setTemperature_dot = b;
localDeviceStatus.setTemperature_dot = b;
b = (byte)((paramArrayOfByte[2] & 0xE0) >> 5);
this.mode = b;
localDeviceStatus.mode = b;

b = (byte)((paramArrayOfByte[10] & 0x4) >> 2);
this.tempUnit = b;
localDeviceStatus.tempUnit = b;
```

### Message/device/command types

```
public abstract interface MsgType
{
  public static final byte DEVICE_CONTROL = 2;
  public static final byte DEVICE_DISCOVER = 1;
  public static final byte DEVICE_EXCEPTIONR = 5;
  public static final byte DEVICE_INFO = 10;
  public static final byte DEVICE_QUERY = 3;
  public static final byte DEVICE_RUN = 4;
}

public abstract interface DeviceType
{
  public static final byte AIR = -84;
  public static final byte CLEANER = -4;
  public static final byte DEHUMIDIFIER = -95;
  public static final byte HUMIDIFIER = -3;
}

public abstract interface CommandType
{
  public static final byte REQ_40 = 64;
  public static final byte REQ_41 = 65;
  public static final byte REQ_B0 = -80;
  public static final byte REQ_B1 = -79;
  public static final byte REQ_B5 = -75;
  public static final byte RESP_40 = -64;
  public static final byte RESP_48 = -56;
  public static final byte RESP_A1 = -95;
  public static final byte RESP_AO = -96;
}

public abstract interface ServerPath
{
  public static final String APPOINT_ADD = "/applianceappoint/addApplianceAppoint";
  public static final String APPOINT_CLOSE = "/applianceappoint/closeApplianceAppoint";
  public static final String APPOINT_LIST = "/applianceappoint/getApplianceAppointList";
  public static final String APPOINT_START = "/applianceappoint/startApplianceAppoint";
  public static final String APPOINT_UPDATE = "/applianceappoint/updateApplianceAppoint";
  public static final String CHECK_DETAILS = "/acCheck/acCheckDetails";
  public static final String CHECK_DEVICE = "/acCheck/startACCheck";
  public static final String CURVE_START = "/sleepcurve/startSleepCurve";
  public static final String CURVE_STOP = "/sleepcurve/closeSleepCurve";
  public static final String ENERGY_CLOSE = "/electricityLimit/stopLimit";
  public static final String ENERGY_LIMIT_QUERY = "/electricityLimit/queryLimit";
  public static final String ENERGY_OPEN = "/electricityLimit/startLimit";
  public static final String ENERGY_QUERY = "/electricity/queryElec";
  public static final String SLEEP_GET = "/sleepcurve/getSleepCurveStatus";
  public static final String SLEEP_UPDATE = "/sleepcurve/updateSleepCurve";
```

### Query bodies

```
--- DataBodyQuery41:
byte[] bytes = { -86, 32, -84, 0, 0, 0, 0, 0, 3, 3, 65, -127, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 16, 83 };

--- DataBodyQueryB1:
byte[] arrayOfByte = new byte[7];
arrayOfByte[0] = -79;
arrayOfByte[1] = 2;
arrayOfByte[2] = 24;
arrayOfByte[3] = 0;
arrayOfByte[4] = 26;
arrayOfByte[5] = 0;
arrayOfByte[(arrayOfByte.length - 1)] = ((byte)getCRC((byte[])arrayOfByte.clone(), arrayOfByte.length - 1));
arrayOfByte = addQueryB5Header(arrayOfByte, (byte)-84);
Log.d("rawData", "result = " + printHexString(arrayOfByte));
return arrayOfByte;

--- DataBodyQueryBFive:
byte[] queryB5 = { -75, 1, 17, 0 };
byte type = -84;

this.queryB5[(this.queryB5.length - 1)] = ((byte)getCRC((byte[])this.queryB5.clone(), this.queryB5.length - 1));
byte[] arrayOfByte = addQueryB5Header(this.queryB5, this.type);
Log.d("rawData", "result = " + printHexString(arrayOfByte));
return arrayOfByte;
```
