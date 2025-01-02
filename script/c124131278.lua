--플라이어 체리 블로썸
local s,id=GetID()
function s.initial_effect(c)
    --링크 소환 방법
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,3,99)
    --상대 필드의 토큰을 링크 소재로 사용
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetProperty(EFFECT_FLAG_PLAYER_TARGET|EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_SET_AVAILABLE)
    e0:SetCode(EFFECT_EXTRA_MATERIAL)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetTargetRange(1,1)
    e0:SetOperation(s.extracon)
    e0:SetValue(s.extraval)
    c:RegisterEffect(e0)
    --상대 필드에 토큰 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DAMAGE_STEP)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.tokencon)
    e1:SetTarget(s.tokentg)
    e1:SetOperation(s.tokenop)
    c:RegisterEffect(e1)
    --상대 묘지로 보내지는 카드 제외
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_TO_GRAVE_REDIRECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(0,0xff)
    e2:SetValue(LOCATION_REMOVED)
    e2:SetCondition(s.rmcon)
    e2:SetTarget(s.rmtg)
    c:RegisterEffect(e2)
end

function s.matfilter(c,lc,stype,tp)
    return c:IsRace(RACE_PLANT,lc,stype,tp)
end

function s.closed_sky_filter(c)
	return not (c:HasFlagEffect(71818935) and #c:GetCardTarget()>0)
end
function s.extracon(c,e,tp,sg,mg,lc,og,chk)
    if not s.curgroup then return true end
    local g=s.curgroup:Filter(s.closed_sky_filter,nil)
    return #(sg&g)<#g+1 -- 변경된 부분: 임의의 수만큼 사용할 수 있도록 조정
end
function s.extraval(chk,summon_type,e,...)
	if chk==0 then
		local tp,sc=...
		if summon_type~=SUMMON_TYPE_LINK or sc~=e:GetHandler() then
			return Group.CreateGroup()
		else
			s.curgroup=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_TOKEN)
			s.curgroup:KeepAlive()
			return s.curgroup
		end
	elseif chk==2 then
		if s.curgroup then
			s.curgroup:DeleteGroup()
		end
		s.curgroup=nil
	end
end

function s.tokencon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and re:IsActiveType(TYPE_MONSTER|TYPE_SPELL|TYPE_TRAP)
end

function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
        and Duel.IsPlayerCanSpecialSummonMonster(tp,124131056,0,TYPES_TOKEN,0,0,1,RACE_PLANT,ATTRIBUTE_DARK) end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

function s.tokenop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<1 or not Duel.IsPlayerCanSpecialSummonMonster(tp,124131056,0,TYPES_TOKEN,0,0,1,RACE_PLANT,ATTRIBUTE_DARK) then return end
    local token=Duel.CreateToken(tp,124131056)
    Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP)
end

function s.rmcon(e)
    return Duel.IsExistingMatchingCard(Card.IsType,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil,TYPE_TOKEN) and Duel.IsExistingMatchingCard(Card.IsRace,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil,RACE_PLANT)
end

function s.rmtg(e,c)
    return c:GetOwner()~=e:GetHandlerPlayer() and Duel.IsPlayerCanRemove(e:GetHandlerPlayer(),c)
end