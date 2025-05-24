--灰滅せし都の呪術師
--Shaman of the Ashened City
--scripted by 유희왕 덱 제작기
local s,id=GetID()
function s.initial_effect(c)
	-- Special Summon from hand if "Obsidim, Ashened City" is on field
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Set 1 Continuous Spell/Trap from Deck upon Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOFIELD)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

-- 카드 참조 코드 (전역 변수)
CARD_OBSIDIM_ASHENED_CITY = 10000010 -- "회멸의 도시 옵시딤"의 가상 코드
SET_ASHENED = 0x2e1 -- 회멸 카드군의 시리얼 번호 (예시값)

------------------------------------------------------
-- 특수 소환 조건: 필드존에 옵시딤 존재 시
------------------------------------------------------
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_OBSIDIM_ASHENED_CITY),
			c:GetControler(),LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

------------------------------------------------------
-- 서치 대상 필터: 회멸 지속 마법/함정
------------------------------------------------------
function s.setfilter(c)
	return c:IsSetCard(SET_ASHENED)
		and (c:IsType(TYPE_CONTINUOUS+TYPE_SPELL) or c:IsType(TYPE_CONTINUOUS+TYPE_TRAP))
		and not c:IsForbidden()
end

------------------------------------------------------
-- 효과 발동 타겟
------------------------------------------------------
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end

------------------------------------------------------
-- 지속 마법/함정 앞면 세트
------------------------------------------------------
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end
