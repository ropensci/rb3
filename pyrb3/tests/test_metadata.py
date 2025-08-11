from pyrb3.metadata import Metadata

def test_metadata_checksum_creation():
    """
    Tests that the checksum is created automatically and is a valid hex digest.
    """
    meta = Metadata(
        template_name="test-template",
        download_args={"year": 2023, "instrument": "ABC"}
    )
    assert isinstance(meta.download_checksum, str)
    assert len(meta.download_checksum) == 64 # SHA256 hex digest length

def test_metadata_checksum_stability():
    """
    Tests that the checksum is stable regardless of argument order.
    """
    meta1 = Metadata(
        template_name="test-template",
        download_args={"year": 2023, "instrument": "ABC"}
    )
    meta2 = Metadata(
        template_name="test-template",
        download_args={"instrument": "ABC", "year": 2023}
    )
    assert meta1.download_checksum == meta2.download_checksum

def test_metadata_checksum_uniqueness():
    """
    Tests that different args produce different checksums.
    """
    meta1 = Metadata(
        template_name="test-template",
        download_args={"year": 2023}
    )
    meta2 = Metadata(
        template_name="test-template",
        download_args={"year": 2024}
    )
    meta3 = Metadata(
        template_name="another-template",
        download_args={"year": 2023}
    )
    assert meta1.download_checksum != meta2.download_checksum
    assert meta1.download_checksum != meta3.download_checksum
