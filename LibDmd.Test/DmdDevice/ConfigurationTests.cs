using System.IO;
using FluentAssertions;
using LibDmd.Common;
using LibDmd.DmdDevice;
using NUnit.Framework;

namespace LibDmd.Test
{
	[TestFixture]
	public class ConfigurationTests
	{
		[TestCase("rotate = cw", FrameRotation.Cw)]
		[TestCase("rotate = ccw", FrameRotation.Ccw)]
		[TestCase("rotate = 180", FrameRotation.Rotate180)]
		[TestCase("rol = true", FrameRotation.Ccw)]
		[TestCase("ror = true", FrameRotation.Cw)]
		public void Should_Parse_Global_Rotation(string rotationConfig, FrameRotation expected)
		{
			var iniPath = Path.GetTempFileName();
			try {
				File.WriteAllText(iniPath, "[global]\n" + rotationConfig + "\n");

				var config = new Configuration(iniPath);

				config.Global.Rotation.Should().Be(expected);
			} finally {
				File.Delete(iniPath);
			}
		}
	}
}
