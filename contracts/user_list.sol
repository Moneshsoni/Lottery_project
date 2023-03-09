// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract List_user{
    address[] users_list;

    event Donate(address users);
    function PleaseDonate()public payable{
        users_list.push(payable(msg.sender));
        emit Donate(msg.sender); 
    }

    function get_users()public view returns(address[] memory){
        return users_list;
    }

    function getLength()public view returns(uint){
        return users_list.length;
    }
}