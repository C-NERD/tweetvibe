def isemptyorspace(data : str) -> bool :
    """
    Checks if string is empty or contains whitespace

    :param data: string to be checked

    retype: bool
    """

    if len(data) == 0 or data.isspace():

        return True
    
    else:

        return False