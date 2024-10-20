--종말의 기도
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
		--cannot attack
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
        e2:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
        e2:SetRange(LOCATION_SZONE)
        e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
        e2:SetCondition(s.atkcon)
        e2:SetTarget(s.atktg)
        c:RegisterEffect(e2)
        --check
        local e4=Effect.CreateEffect(c)
        e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e4:SetCode(EVENT_ATTACK_ANNOUNCE)
        e4:SetRange(LOCATION_SZONE)
        e4:SetOperation(s.checkop)
        e4:SetLabelObject(e2)
        c:RegisterEffect(e4)
    --Place 1 "Branded" Continuous Spell/Trap on the field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id)
    e3:SetCondition(s.discon)
	e3:SetTarget(s.tftg)
	e3:SetOperation(s.tfop)
	c:RegisterEffect(e3)
    	--Register that a player has activated "Millennium Ankh" during this Duel
		aux.GlobalCheck(s,function()
			local ge1=Effect.CreateEffect(c)
			ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			ge1:SetCode(EVENT_CHAIN_SOLVED)
			ge1:SetOperation(s.regop)
			Duel.RegisterEffect(ge1,0)
		end)
	end
	s.listed_names={95308449} --"종언의 카운트 다운"
	function s.regop(e,tp,eg,ep,ev,re,r,rp)
		if not Duel.HasFlagEffect(rp,id) and re:GetHandler():IsCode(95308449) and re:IsHasType(EFFECT_TYPE_ACTIVATE) then
			Duel.RegisterFlagEffect(rp,id,0,0,0)
		end
	end	
    function s.atkcon(e)
        return e:GetHandler():GetFlagEffect(id)~=0
    end
    function s.atktg(e,c)
        return c:GetFieldID()~=e:GetLabel()
    end
    function s.checkop(e,tp,eg,ep,ev,re,r,rp)
        if e:GetHandler():GetFlagEffect(id)~=0 then return end
        local fid=eg:GetFirst():GetFieldID()
        e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
        e:GetLabelObject():SetLabel(fid)
    end
    
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.HasFlagEffect(tp,id)
end

function s.tffilter(c,tp)
	return c:IsSpellTrap() and c:IsType(TYPE_CONTINUOUS) and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end
function s.tftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.tffilter(chkc,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.tffilter,tp,LOCATION_GRAVE,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectTarget(tp,s.tffilter,tp,LOCATION_GRAVE,0,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,tp,0)
end
function s.tfop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)==0 then return end
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end