using System;
using System.Configuration;

public class Program
{
	public static void Main()
	{
		Console.WriteLine("The app is running, press enter to quit.");

		var appSettings = ConfigurationManager.AppSettings;
        foreach (var key in appSettings.AllKeys)
        {
            Console.WriteLine("Setting '{0}' = '{1}'", key, appSettings[key]);
        }

		Console.ReadLine();
	}
}
