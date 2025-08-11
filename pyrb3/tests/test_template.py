import pytest
from pyrb3.template import Template

def test_load_template_successfully():
    """
    Tests that a known template is loaded and parsed correctly.
    """
    template_name = "b3-cotahist-yearly"
    template = Template(template_name)

    assert template.name == template_name
    assert template.id == "b3-cotahist-yearly"
    assert "function" in template.downloader
    assert "function" in template.reader
    assert isinstance(template.fields, list)
    assert len(template.fields) > 0

def test_load_nonexistent_template():
    """
    Tests that trying to load a template that does not exist raises an error.
    """
    with pytest.raises(FileNotFoundError):
        Template("nonexistent-template")
