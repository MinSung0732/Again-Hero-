"""Inverse only observation hooks; gameplay bodies remain the baseline oracle."""
import re

def normalize_legacy_status(body):
    if 'legacy_status_result_complete = legacy_status_receipt.finish' not in body:
        return body
    body = re.sub(r'\tvar revision: int = legacy_status_receipt.begin\([^\n]+\)\n', '', body)
    body = re.sub(r'\tlegacy_status_result_complete = legacy_status_receipt.finish\(revision\)\n', '', body)
    body = body.replace(', legacy_status_receipt, revision)', ')')
    body = body.replace('\tvar accepted: bool = _apply_', '\treturn _apply_')
    return body.replace('\treturn accepted\n', '')

def normalize_component(body):
    body = re.sub(r'^const STATUS_RECEIPT[^\n]+\n|^var status_receipt[^\n]+\n|^var status_result_complete[^\n]+\n', '', body, flags=re.M)
    body = re.sub(r'^\tvar status_revision: int = node.status_receipt.begin[^\n]+\n|^\t+node.status_receipt.record_[^\n]+\n|^\tnode.status_result_complete = node.status_receipt.finish[^\n]+\n|^\tstatus_result_complete = false\n', '', body, flags=re.M)
    if 'var accepted := bool(node.poison.apply' in body:
        body = re.sub(r'\tvar accepted := (bool\(node.poison.apply[^\n]+)\n\tif accepted:\n\treturn accepted', r'\treturn \1', body)
    body = re.sub(r'(\tif [^\n]+:)\n\t\t_invalidate_component_result\(actor\)\n\t\t(return(?: false)?)', r'\1 \2', body)
    return body
