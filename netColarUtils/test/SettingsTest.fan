// History:
//   Apr 29, 2011 thibaut Creation
//

**
** SettingsTest
**
class SettingsTest : Test
{
  Void testSettings()
  {
    settings := SettingUtils
    {
      headComments =
      [
    "This is the setting file for Dummy Test 1.3",
    "Feel free to change stuff !"
      ]

      tailComments =
      [
    "------------ The End !! -------------------",
      ]
    }

    s := MySettings {}
    f := File(`/tmp/settings.txt`).deleteOnExit
    settings.save(s, f.out)

    // save & read
    MySettings? s2 := settings.read(MySettings#, f.in) as MySettings

    validateSettings(s, s2)

    // change values and test save/read
    s.port = 1000
    s.host = "tesHost"
    s.notSaved = 0
    s.paths = ["test1", "test2"]
    settings.save(s, f.out)
    s2 = settings.read(MySettings#, f.in) as MySettings

    validateSettings(s, s2)
    verifyEq(s.notSaved, 0)
    verifyEq(s2.notSaved, 5)

    // Testing in-place update
    // add user comments and test update/read
    lines := f.readAllLines
    lines.insert(0, "# Custom comment 1")
    lines.add("# Custom comment 2")
    out:=f.out
    lines.each {out.printLine(it)}
    out.close
    //changes values
    s.port = 2000
    s.host = "testHost2"
    s.notSaved = 1
    s.paths = ["test2", "test3"]
    settings.update(s, f)
    s2 = settings.read(MySettings#, f.in)

    validateSettings(s, s2)
    verifyEq(s.notSaved, 1)
    verifyEq(s2.notSaved, 5)

    lines = f.readAllLines
    verifyEq(lines[0], "# Custom comment 1")
    verifyEq(lines[-1], "# Custom comment 2")

    // check nullable exception
    s3 := BrokenSettings {}
    verifyErr(Err#) { settings.update(s3, f) }
  }

  ** Validate s and s2 have the same values
  Void validateSettings(MySettings s, MySettings s2)
  {
    verifyEq(s.port, s2.port)
    verifyEq(s.host, s2.host)
    verifyEq(s.paths, s2.paths)
    verifyEq(s.complex.bar, s2.complex.bar)
    verifyEq(s.complex.foo, s2.complex.foo)
  }

}

class MySettings
{
  new make(|This| f) {f(this)}

  @Setting
  Int port := 8080

  @Setting{help = ["The host"]; category = "server"}
  Str host := "127.0.0.1"

  @Setting{help = ["The paths", "That's just a test"]}
  Str[] paths := ["path1", "path2"]

  @Setting{help = ["It's complicated"] }
  ComplexSetting complex := ComplexSetting {}

  Int notSaved := 5
}

class BrokenSettings
{
  new make(|This| f) {f(this)}

  @Setting{help = ["Nullable"] }
  Int? Nullable
}

@Serializable
class ComplexSetting
{
  new make(|This| f) {f(this)}

  Str bar := "bar"
  Int foo := 5
  Str? someNullThing
}